import type { ExtensionAPI, ExtensionContext, ReadonlyFooterDataProvider } from "@mariozechner/pi-coding-agent";
import { execFile } from "node:child_process";
import { promises as fs } from "node:fs";
import { basename, join } from "node:path";
import { promisify } from "node:util";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

type Theme = ExtensionContext["ui"]["theme"];
type ThinkingLevel = ReturnType<ExtensionAPI["getThinkingLevel"]>;
type GitStats = { additions: number; deletions: number } | null;

const execFileAsync = promisify(execFile);
const MAX_UNTRACKED_FILE_BYTES = 1024 * 1024;

function formatTokens(count: number): string {
	if (count < 1000) return count.toString();
	if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
	if (count < 1000000) return `${Math.round(count / 1000)}k`;
	if (count < 10000000) return `${(count / 1000000).toFixed(1)}M`;
	return `${Math.round(count / 1000000)}M`;
}

function formatFolder(cwd: string): string {
	const trimmed = cwd.replace(/[\\/]+$/, "");
	if (!trimmed) return cwd;
	return basename(trimmed) || trimmed;
}


function shellBlue(text: string): string {
	return `\x1b[34m${text}\x1b[39m`;
}

function shellGreen(text: string): string {
	return `\x1b[32m${text}\x1b[39m`;
}

function shellRed(text: string): string {
	return `\x1b[31m${text}\x1b[39m`;
}

function gitStatsText(stats: GitStats): string {
	if (!stats || (stats.additions === 0 && stats.deletions === 0)) return "";
	return ` ${shellGreen(`+${stats.additions}`)} ${shellRed(`-${stats.deletions}`)}`;
}

function folderWithBranch(ctx: ExtensionContext, footerData: ReadonlyFooterDataProvider, gitStats: GitStats): string {
	const folder = shellBlue(formatFolder(ctx.cwd));
	const branch = footerData.getGitBranch();
	const stats = gitStatsText(gitStats);
	return branch ? `${folder}${shellGreen(` (${branch})`)}${stats}` : `${folder}${stats}`;
}

function contextUsageText(ctx: ExtensionContext, theme: Theme): string {
	const usage = ctx.getContextUsage();
	const tokens = usage?.tokens ?? null;
	const text = tokens === null ? "?" : formatTokens(tokens);

	if (tokens === null) return theme.fg("dim", text);
	if (tokens >= 100_000) return theme.fg("error", text);
	if (tokens >= 50_000) return theme.fg("warning", text);
	return theme.fg("muted", text);
}

function modelText(ctx: ExtensionContext, theme: Theme): string {
	const model = ctx.model;
	if (!model) return theme.fg("dim", "?");
	return theme.fg("muted", `${model.provider}/${model.id}`);
}

function thinkingLevelText(level: ThinkingLevel, theme: Theme): string {
	return theme.fg("muted", level);
}

function renderFooterLine(
	ctx: ExtensionContext,
	theme: Theme,
	footerData: ReadonlyFooterDataProvider,
	width: number,
	thinkingLevel: ThinkingLevel,
	gitStats: GitStats,
): string {
	if (width <= 0) return "";

	const ellipsis = theme.fg("dim", "...");
	const left = folderWithBranch(ctx, footerData, gitStats);
	const right = `${contextUsageText(ctx, theme)} ${modelText(ctx, theme)} ${thinkingLevelText(thinkingLevel, theme)}`;
	const rightWidth = visibleWidth(right);

	if (rightWidth >= width) {
		return truncateToWidth(right, width, ellipsis);
	}

	const leftWidth = Math.max(0, width - rightWidth - 1);
	const visibleLeft = truncateToWidth(left, leftWidth, ellipsis);
	const padding = " ".repeat(Math.max(1, width - visibleWidth(visibleLeft) - rightWidth));

	return truncateToWidth(visibleLeft + padding + right, width, ellipsis);
}

function countTextLines(buffer: Buffer): number {
	if (buffer.length === 0 || buffer.includes(0)) return 0;

	let lines = 0;
	for (const byte of buffer) {
		if (byte === 10) lines++;
	}
	return buffer.at(-1) === 10 ? lines : lines + 1;
}

async function countUntrackedAdditions(cwd: string): Promise<number> {
	const { stdout } = await execFileAsync("git", ["-C", cwd, "ls-files", "--others", "--exclude-standard", "-z"], {
		timeout: 5000,
		maxBuffer: 1024 * 1024,
		encoding: "buffer",
	});

	let additions = 0;
	for (const file of stdout.toString("utf8").split("\0")) {
		if (!file) continue;

		try {
			const path = join(cwd, file);
			const stat = await fs.stat(path);
			if (!stat.isFile() || stat.size > MAX_UNTRACKED_FILE_BYTES) continue;
			additions += countTextLines(await fs.readFile(path));
		} catch {
			// Ignore files that disappeared or cannot be read while stats are refreshing.
		}
	}

	return additions;
}

async function getGitStats(cwd: string): Promise<GitStats> {
	try {
		const { stdout } = await execFileAsync("git", ["-C", cwd, "diff", "--numstat", "HEAD", "--"], {
			timeout: 5000,
			maxBuffer: 1024 * 1024,
		});
		let additions = 0;
		let deletions = 0;

		for (const line of stdout.trim().split("\n")) {
			if (!line) continue;
			const [added, deleted] = line.split("\t");
			if (added !== "-") additions += Number(added) || 0;
			if (deleted !== "-") deletions += Number(deleted) || 0;
		}

		additions += await countUntrackedAdditions(cwd);

		return { additions, deletions };
	} catch {
		return null;
	}
}

export default function (pi: ExtensionAPI) {
	let requestFooterRender: (() => void) | undefined;
	let gitStats: GitStats = null;
	let refreshGitStats: (() => void) | undefined;

	pi.on("session_start", async (_event, ctx) => {
		const updateGitStats = async () => {
			const nextStats = await getGitStats(ctx.cwd);
			if (nextStats?.additions === gitStats?.additions && nextStats?.deletions === gitStats?.deletions) return;
			gitStats = nextStats;
			requestFooterRender?.();
		};
		refreshGitStats = () => void updateGitStats();
		refreshGitStats();

		ctx.ui.setFooter((tui, theme, footerData) => {
			const requestRender = () => tui.requestRender();
			const unsubscribeBranchChange = footerData.onBranchChange(() => {
				requestRender();
				refreshGitStats?.();
			});
			requestFooterRender = requestRender;

			return {
				dispose() {
					unsubscribeBranchChange();
					if (requestFooterRender === requestRender) {
						requestFooterRender = undefined;
					}
				},
				invalidate() {},
				render(width: number): string[] {
					return [renderFooterLine(ctx, theme, footerData, width, pi.getThinkingLevel(), gitStats)];
				},
			};
		});
	});

	pi.on("model_select", async () => requestFooterRender?.());
	pi.on("thinking_level_select", async () => requestFooterRender?.());
	pi.on("message_end", async () => {
		refreshGitStats?.();
		requestFooterRender?.();
	});
	pi.on("turn_end", async () => {
		refreshGitStats?.();
		requestFooterRender?.();
	});
}
