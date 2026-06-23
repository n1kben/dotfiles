---
name: checkpoint
description: Preserve continuity for a future session resuming the same unfinished work.
argument-hint: "What should the next session focus on?"
disable-model-invocation: true
---

Create a checkpoint for a future session that will resume this same, unfinished work.

The future session has the codebase, history, tests, issues, ADRs, plans, and diffs — but not this conversation. So capture only the reasoning that currently lives *only* in this conversation and has not been written to any artifact yet. That reasoning is the whole payload; everything else is rediscoverable.

Record **why**, not **what**. "Decided X" is recoverable — the next session sees X in the diff. "Decided X because Y, having rejected Z because W" is not recoverable from anything. The decision is in the checkpoint only as the hook its reasoning hangs on.

Do not summarize the conversation. The events are not the payload; the reasoning is.

Capture, where present:

- decisions made, and why
- alternatives considered and rejected, and why
- preferences expressed
- open questions still unresolved
- concrete next steps

Omit any category with nothing in it — write no empty headings.

Hang references off the decision they justify, inline (`path:line`, an issue, an ADR) — never collect a standalone "reference files" section. Exception: when the *set* of files in play is itself the state (a multi-file refactor), list them, because the set is not rediscoverable. Inline a code snippet only when it pins a decision more precisely than prose can (a type shape, a schema), never as decoration.

Do not duplicate anything already captured in code, commits, or other artifacts. Reference sources of truth instead of restating them.

If arguments were provided, treat them as the next session's focus and prioritize reasoning relevant to it.

Be concise.

Write the checkpoint to a temp file via `mktemp -t checkpoint-XXXXXX.md` (read the file before writing), then also print the full checkpoint inline.
