/**
 * Parallel Inline Bash Extension - expands inline bash commands in user prompts.
 *
 * Start pi with this extension:
 *   pi -e ./examples/extensions/parallel-inline-bash.ts
 *
 * Then type prompts with inline bash:
 *   What's in !{pwd}?
 *   The current branch is !{git branch --show-current} and status: !{git status --short}
 *   My node version is !{node --version}
 *
 * The !{command} patterns are executed in parallel and replaced with their
 * output before the prompt is sent to the agent.
 *
 * Note: Regular !command syntax (whole-line bash) is preserved and works as before.
 */
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	const PATTERN = /!\{([^}]+)\}/g;
	const TIMEOUT_MS = 30000;

	async function expandInlineBash(text: string) {
		// Check if there are any inline bash patterns
		if (!PATTERN.test(text)) {
			return { text, expansions: [] };
		}

		// Reset regex state after test()
		PATTERN.lastIndex = 0;

		// Find all matches first (to avoid issues with replacing while iterating)
		const matches: Array<{ full: string; command: string }> = [];
		let match = PATTERN.exec(text);
		while (match) {
			const command = match[1].trim();
			if (command !== "...") {
				matches.push({ full: match[0], command: match[1] });
			}
			match = PATTERN.exec(text);
		}

		// Execute commands in parallel, while Promise.all preserves match order.
		const expansions = await Promise.all(
			matches.map(async ({ command }) => {
				try {
					const bashResult = await pi.exec("bash", ["-c", command], {
						timeout: TIMEOUT_MS,
					});

					const output = bashResult.stdout || bashResult.stderr || "";
					const formatted = output.trimEnd();

					if (bashResult.code !== 0 && bashResult.stderr) {
						return {
							command,
							output: formatted,
							replacement: formatted,
							error: `exit code ${bashResult.code}`,
						};
					}

					return { command, output: formatted, replacement: formatted };
				} catch (err) {
					const errorMsg = err instanceof Error ? err.message : String(err);
					return { command, output: "", replacement: `[error: ${errorMsg}]`, error: errorMsg };
				}
			}),
		);

		let result = text;
		for (let i = 0; i < matches.length; i++) {
			result = result.replace(matches[i].full, expansions[i].replacement);
		}

		return { text: result, expansions };
	}

	function notifyExpansions(ctx: ExtensionContext, expansions: Array<{ command: string; output: string; error?: string }>) {
		// Show what was expanded (if UI available)
		if (!ctx.hasUI || expansions.length === 0) return;

		const summary = expansions
			.map((e) => {
				const status = e.error ? ` (${e.error})` : "";
				const preview = e.output.length > 50 ? `${e.output.slice(0, 50)}...` : e.output;
				return `!{${e.command}}${status} -> "${preview}"`;
			})
			.join("\n");

		ctx.ui.notify(`Expanded ${expansions.length} inline command(s):\n${summary}`, "info");
	}

	pi.on("before_agent_start", async (event) => {
		return {
			systemPrompt:
				event.systemPrompt +
				`\n\nParallel inline bash: When you need to run multiple independent bash commands in parallel, write \`!{command}\` expressions in assistant text. The extension executes all inline commands in parallel with a 30s timeout and replaces each expression with stdout, or stderr/error text on failure, with only the trailing newline removed. Use this for independent read-only inspections or parallel \`pi -p\` sub-agent queries. Do not use it for commands that depend on each other, mutate shared state, require interaction, or need long-running/background execution; use the bash tool instead.

Example:
\`\`\`md
Spawn a sub pi session that explores git history for related changes:
!{pi -p "Explore git history for changes related to <topic>. Return concise findings with commit hashes."}

Spawn a sub pi session that reviews the current implementation:
!{pi -p "Review <files or topic>. Return risks, relevant files, and suggested next steps."}
\`\`\``,
		};
	});

	pi.on("input", async (event, ctx) => {
		const text = event.text;

		// Don't process if it's a whole-line bash command (starts with !)
		// This preserves the existing !command behavior
		if (text.trimStart().startsWith("!") && !text.trimStart().startsWith("!{")) {
			return { action: "continue" };
		}

		const expanded = await expandInlineBash(text);
		if (expanded.expansions.length === 0) return { action: "continue" };

		notifyExpansions(ctx, expanded.expansions);
		return { action: "transform", text: expanded.text, images: event.images };
	});

	pi.on("message_end", async (event, ctx) => {
		if (event.message.role !== "assistant") return;

		let changed = false;
		const expansions: Array<{ command: string; output: string; error?: string }> = [];
		const content = await Promise.all(
			event.message.content.map(async (block) => {
				if (block.type !== "text") return block;
				const expanded = await expandInlineBash(block.text);
				if (expanded.expansions.length === 0) return block;
				changed = true;
				expansions.push(...expanded.expansions);
				return { ...block, text: expanded.text };
			}),
		);

		if (!changed) return;
		notifyExpansions(ctx, expansions);
		return { message: { ...event.message, content } };
	});
}
