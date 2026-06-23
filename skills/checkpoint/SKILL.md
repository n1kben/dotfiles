---
name: checkpoint
description: Preserve continuity for a future session resuming unfinished work.
argument-hint: "What should the next session focus on?"
disable-model-invocation: true
---

Create a checkpoint for a future session that will resume this work.

The future session has access to project artifacts. It does not have access to this conversation.

Capture the context, reasoning, decisions, tradeoffs, assumptions, open questions, and current direction that would otherwise be lost.

The goal is to allow the next session to continue the work without repeating important exploration.

Record why things matter, not just what happened.

Capture the state of the work, not the history of the conversation.

Use the smallest structure that preserves continuity:

## Context

Important framing, goals, constraints, priorities, assumptions, tradeoffs, intent, or discoveries that shape the work.

## Decisions

Decisions made, why they were made, alternatives considered, alternatives rejected, and any reasoning that would be difficult to reconstruct later.

Mark decisions as tentative when they are not yet settled.

## Open Questions

Known unknowns, unresolved decisions, risks, investigations in progress, or areas where confidence remains low.

## Next Steps

The most likely next actions, investigations, validations, or decision points.

Reference artifacts as sources of truth and focus on the context that surrounds them.

Attach references to the decisions they support rather than collecting them separately.

Include files when the set of files is itself important state that the next session would benefit from preserving.

If arguments were provided, treat them as the next session's focus and prioritize information relevant to that work.

Be concise, but preserve enough context that the next session can continue without redoing important thinking.

Write the checkpoint to a temp file via `mktemp -t checkpoint-XXXXXX.md` (read the file before writing), then also print the full checkpoint inline.
