import type { ExtensionAPI, ExtensionContext, ReadonlyFooterDataProvider } from "@mariozechner/pi-coding-agent";
import { basename } from "node:path";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

type Theme = ExtensionContext["ui"]["theme"];
type ThinkingLevel = ReturnType<ExtensionAPI["getThinkingLevel"]>;

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

function extensionStatusesText(footerData: ReadonlyFooterDataProvider, theme: Theme): string {
	return [...footerData.getExtensionStatuses().values()].filter(Boolean).join(` ${theme.fg("muted", "·")} `);
}

function renderFooterLine(
	ctx: ExtensionContext,
	theme: Theme,
	footerData: ReadonlyFooterDataProvider,
	width: number,
	thinkingLevel: ThinkingLevel,
): string {
	if (width <= 0) return "";

	const ellipsis = theme.fg("dim", "...");
	const leftParts = [shellBlue(formatFolder(ctx.cwd)), extensionStatusesText(footerData, theme)].filter(Boolean);
	const left = leftParts.join(" ");
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

export default function (pi: ExtensionAPI) {
	let requestFooterRender: (() => void) | undefined;

	pi.on("session_start", async (_event, ctx) => {
		ctx.ui.setFooter((tui, theme, footerData) => {
			const requestRender = () => tui.requestRender();
			requestFooterRender = requestRender;

			return {
				dispose() {
					if (requestFooterRender === requestRender) {
						requestFooterRender = undefined;
					}
				},
				invalidate() {},
				render(width: number): string[] {
					return [renderFooterLine(ctx, theme, footerData, width, pi.getThinkingLevel())];
				},
			};
		});
	});

	pi.on("model_select", async () => requestFooterRender?.());
	pi.on("thinking_level_select", async () => requestFooterRender?.());
	pi.on("message_end", async () => requestFooterRender?.());
	pi.on("turn_end", async () => requestFooterRender?.());
}
