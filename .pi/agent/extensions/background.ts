import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const REFRESH_INTERVAL_MS = 10_000;

function backgroundPrompt(): string {
	return "Background jobs: If the user asks to run something in the background, start a server, watch logs, or perform long-running work, use detached tmux sessions rather than blocking the current shell. Use descriptive session names. Do not use tmux for short foreground commands.";
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

async function listTmuxSessions(): Promise<Set<string>> {
	try {
		const { stdout } = await execFileAsync("tmux", ["list-sessions", "-F", "#{session_name}\t#{session_created}"], {
			timeout: 2000,
			maxBuffer: 64 * 1024,
		});

		return new Set(
			stdout
				.split("\n")
				.map((line): BackgroundSession | null => {
					const [name, createdText] = line.split("\t");
					if (!name) return null;
					return { name: name.trim(), created: Number(createdText) || 0 };
				})
				.filter((session): session is BackgroundSession => Boolean(session?.name))
				.sort((a, b) => a.name.localeCompare(b.name))
				.map((session) => session.name),
		);
	} catch {
		return new Set();
	}
}

async function listBackgroundSessions(trackedSessions: Set<string>): Promise<string[]> {
	const existing = await listTmuxSessions();
	for (const session of trackedSessions) {
		if (!existing.has(session)) trackedSessions.delete(session);
	}
	return [...trackedSessions].sort((a, b) => a.localeCompare(b));
}

function formatBackgroundStatus(sessions: string[]): string | undefined {
	if (sessions.length === 0) return undefined;
	const shown = sessions.slice(0, 3).join(", ");
	const extra = sessions.length > 3 ? ` +${sessions.length - 3}` : "";
	return `bg: ${shown}${extra}`;
}

async function refreshBackgroundStatus(ctx: ExtensionContext, trackedSessions: Set<string>) {
	if (!ctx.hasUI) return;
	const status = formatBackgroundStatus(await listBackgroundSessions(trackedSessions));
	ctx.ui.setStatus("background", status);
	const widgetStatus = status?.replace(/^bg: /, "");
	ctx.ui.setWidget(
		"background",
		widgetStatus ? [`${widgetStatus}  ${ctx.ui.theme.fg("muted", "(/bg for details)")}`] : undefined,
	);
}

function shellWords(command: string): string[] {
	const words: string[] = [];
	let current = "";
	let quote: "'" | '"' | undefined;
	let escaping = false;

	for (const char of command) {
		if (escaping) {
			current += char;
			escaping = false;
			continue;
		}
		if (char === "\\" && quote !== "'") {
			escaping = true;
			continue;
		}
		if (quote) {
			if (char === quote) quote = undefined;
			else current += char;
			continue;
		}
		if (char === "'" || char === '"') {
			quote = char;
			continue;
		}
		if (/\s/.test(char)) {
			if (current) {
				words.push(current);
				current = "";
			}
			continue;
		}
		current += char;
	}
	if (current) words.push(current);
	return words;
}

function splitShellCommands(command: string): string[] {
	return command
		.split(/(?:^|[;&|])\s*/g)
		.map((part) => part.trim())
		.filter(Boolean);
}

function tmuxSessionNamesFromCommand(command: string): string[] {
	const names = new Set<string>();
	for (const part of splitShellCommands(command)) {
		const words = shellWords(part);
		if (words[0] !== "tmux") continue;
		if (!["new-session", "new"].includes(words[1] ?? "")) continue;

		let detached = false;
		let sessionName: string | undefined;
		for (let i = 2; i < words.length; i++) {
			const word = words[i];
			if (word === "-d" || /^-[^-].*d/.test(word)) detached = true;
			if (word === "-s" || word === "--session-name") sessionName = words[++i];
			else if (word.startsWith("-s") && word.length > 2) sessionName = word.slice(2);
		}
		if (detached && sessionName) names.add(sessionName);
	}
	return [...names];
}

export default function (pi: ExtensionAPI) {
	let interval: NodeJS.Timeout | undefined;
	let refresh: (() => void) | undefined;
	const trackedSessions = new Set<string>();

	async function killTrackedSessions() {
		const sessions = await listBackgroundSessions(trackedSessions);
		await Promise.all(sessions.map((session) => killSession(session).catch(() => undefined)));
		trackedSessions.clear();
	}

	async function confirmAndKillTrackedSessions(ctx: ExtensionContext, action: string): Promise<boolean> {
		const sessions = await listBackgroundSessions(trackedSessions);
		if (sessions.length === 0) return true;
		if (!ctx.hasUI) {
			await killTrackedSessions();
			return true;
		}

		const confirmed = await ctx.ui.confirm(
			`${action}?`,
			`This will kill ${sessions.length} tracked tmux background session(s):\n\n${sessions.join("\n")}\n\nContinue?`,
		);
		if (!confirmed) return false;
		await killTrackedSessions();
		await refreshBackgroundStatus(ctx, trackedSessions);
		return true;
	}

	pi.registerCommand("bg", {
		description: "View tracked tmux background sessions",
		handler: async (_args, ctx) => {
			const sessions = await listBackgroundSessions(trackedSessions);
			if (!ctx.hasUI) return;

			if (sessions.length === 0) {
				ctx.ui.notify("No tracked background sessions found.", "info");
				await refreshBackgroundStatus(ctx, trackedSessions);
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
				await refreshBackgroundStatus(ctx, trackedSessions);
			}
		},
	});

	pi.on("before_agent_start", async (event) => {
		return {
			systemPrompt: `${event.systemPrompt}\n\n${backgroundPrompt()}`,
		};
	});

	pi.on("session_start", async (_event, ctx) => {
		refresh = () => void refreshBackgroundStatus(ctx, trackedSessions);
		refresh();
		interval = setInterval(refresh, REFRESH_INTERVAL_MS);
	});

	pi.on("tool_result", async (event, ctx) => {
		if (event.toolName !== "bash" || event.isError) return;
		const command = typeof event.input.command === "string" ? event.input.command : undefined;
		if (!command) return;
		const names = tmuxSessionNamesFromCommand(command);
		for (const name of names) trackedSessions.add(name);
		if (names.length > 0) await refreshBackgroundStatus(ctx, trackedSessions);
	});

	pi.on("message_end", async () => refresh?.());
	pi.on("turn_end", async () => refresh?.());

	pi.on("session_before_switch", async (event, ctx) => {
		const confirmed = await confirmAndKillTrackedSessions(
			ctx,
			event.reason === "new" ? "Start a new session" : "Resume another session",
		);
		return confirmed ? undefined : { cancel: true };
	});

	pi.on("session_before_fork", async (_event, ctx) => {
		const confirmed = await confirmAndKillTrackedSessions(ctx, "Fork this session");
		return confirmed ? undefined : { cancel: true };
	});

	pi.on("session_shutdown", async (event, ctx) => {
		if (interval) clearInterval(interval);
		interval = undefined;
		refresh = undefined;

		const sessions = await listBackgroundSessions(trackedSessions);
		if (sessions.length > 0) {
			await killTrackedSessions();
			if (ctx.hasUI) {
				ctx.ui.notify(`Killed ${sessions.length} tracked background session(s) for ${event.reason}.`, "info");
			}
		}

		if (ctx.hasUI) {
			ctx.ui.setStatus("background", undefined);
			ctx.ui.setWidget("background", undefined);
		}
	});
}
