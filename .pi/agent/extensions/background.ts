import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { execFile } from "node:child_process";
import { basename } from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const SESSION_PREFIX = "pi-";
const REFRESH_INTERVAL_MS = 10_000;

function backgroundPrompt(sessionPrefix: string): string {
	return `Background jobs: If the user asks to run something in the background, keep a server/process running, watch logs, or perform long-running work, use tmux rather than blocking the current shell. The user does not need to already be inside tmux. For pi-managed jobs in this session, use session names prefixed with \`${sessionPrefix}\`, e.g. \`tmux new-session -d -s ${sessionPrefix}<descriptive-name> '<command>'\`. Inspect output with \`tmux capture-pane -pt <name>\`, attach when useful with \`tmux attach -t <name>\`, and stop it with \`tmux kill-session -t <name>\`. Choose descriptive session names and tell the user how to inspect or stop the job. Do not use tmux for short foreground commands. Only treat tmux sessions with the \`${sessionPrefix}\` prefix as managed background jobs. When ending a pi session, the user may choose to keep these jobs so they remain visible after resuming the same pi session.`;
}

function sessionPrefixFromFile(sessionFile: string | undefined): string {
	const fallback = `${process.pid}`;
	const source = sessionFile ?? fallback;
	const uuid = source.match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i)?.[0];
	const id = (uuid ?? basename(source).replace(/\.[^.]+$/, ""))
		.replace(/[^a-zA-Z0-9_-]+/g, "-")
		.slice(0, 12);
	return `${SESSION_PREFIX}${id}-`;
}

type BackgroundSession = { name: string; created: number };

async function captureSession(name: string): Promise<string> {
	const { stdout } = await execFileAsync("tmux", ["capture-pane", "-pt", name, "-S", "-"], {
		timeout: 2000,
		maxBuffer: 1024 * 1024,
	});
	return stdout;
}

async function killSession(name: string): Promise<void> {
	await execFileAsync("tmux", ["kill-session", "-t", name], { timeout: 2000 });
}

async function listBackgroundSessions(prefix = SESSION_PREFIX): Promise<string[]> {
	try {
		const { stdout } = await execFileAsync("tmux", ["list-sessions", "-F", "#{session_name}\t#{session_created}"], {
			timeout: 2000,
			maxBuffer: 64 * 1024,
		});

		return stdout
			.split("\n")
			.map((line): BackgroundSession | null => {
				const [name, createdText] = line.split("\t");
				if (!name) return null;
				return { name: name.trim(), created: Number(createdText) || 0 };
			})
			.filter((session): session is BackgroundSession => Boolean(session?.name.startsWith(prefix)))
			.sort((a, b) => a.name.localeCompare(b.name))
			.map((session) => session.name);
	} catch {
		return [];
	}
}

function formatBackgroundStatus(sessions: string[], prefix = SESSION_PREFIX): string | undefined {
	if (sessions.length === 0) return undefined;
	const names = sessions.map((name) => name.slice(prefix.length));
	const shown = names.slice(0, 3).join(", ");
	const extra = names.length > 3 ? ` +${names.length - 3}` : "";
	return `bg: ${shown}${extra}`;
}

async function refreshBackgroundStatus(ctx: ExtensionContext, prefix = SESSION_PREFIX) {
	if (!ctx.hasUI) return;
	const status = formatBackgroundStatus(await listBackgroundSessions(prefix), prefix);
	ctx.ui.setStatus("background", status);
	const widgetStatus = status?.replace(/^bg: /, "");
	ctx.ui.setWidget(
		"background",
		widgetStatus ? [`${widgetStatus}  ${ctx.ui.theme.fg("muted", "(/bg for details)")}`] : undefined,
	);
}

export default function (pi: ExtensionAPI) {
	let interval: NodeJS.Timeout | undefined;
	let refresh: (() => void) | undefined;
	let sessionPrefix = SESSION_PREFIX;

	pi.registerCommand("bg", {
		description: "View pi-managed tmux background sessions",
		handler: async (_args, ctx) => {
			const sessions = await listBackgroundSessions(sessionPrefix);
			if (!ctx.hasUI) return;

			if (sessions.length === 0) {
				ctx.ui.notify("No pi background sessions found.", "info");
				await refreshBackgroundStatus(ctx, sessionPrefix);
				return;
			}

			const session = await ctx.ui.select("Background sessions", sessions);
			if (!session) return;

			try {
				const content = await captureSession(session);
				await ctx.ui.editor(`bg: ${session}`, content);
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				ctx.ui.notify(`Failed to capture ${session}: ${message}`, "error");
			} finally {
				await refreshBackgroundStatus(ctx, sessionPrefix);
			}
		},
	});

	pi.on("before_agent_start", async (event) => {
		return {
			systemPrompt: `${event.systemPrompt}\n\n${backgroundPrompt(sessionPrefix)}`,
		};
	});

	pi.on("session_start", async (_event, ctx) => {
		sessionPrefix = sessionPrefixFromFile(ctx.sessionManager.getSessionFile());
		refresh = () => void refreshBackgroundStatus(ctx, sessionPrefix);
		refresh();
		interval = setInterval(refresh, REFRESH_INTERVAL_MS);
	});

	pi.on("message_end", async () => refresh?.());
	pi.on("turn_end", async () => refresh?.());

	pi.on("session_shutdown", async (event, ctx) => {
		if (interval) clearInterval(interval);
		interval = undefined;
		refresh = undefined;

		const sessions = await listBackgroundSessions(sessionPrefix);
		let keep = false;
		if (sessions.length > 0 && ctx.hasUI) {
			keep = await ctx.ui.confirm(
				"Keep background sessions?",
				`Keep ${sessions.length} pi-managed tmux session(s) running after this session ${event.reason}?\n\nChoose No to kill them now.\n\n${sessions.join("\n")}`,
			);
		}
		if (sessions.length > 0 && !keep) {
			await Promise.all(sessions.map((session) => killSession(session).catch(() => undefined)));
		}

		if (ctx.hasUI) {
			ctx.ui.setStatus("background", undefined);
			ctx.ui.setWidget("background", undefined);
		}
	});
}
