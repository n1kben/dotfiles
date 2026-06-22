---
name: checkpoint
description: Preserve continuity for a future agent.
argument-hint: "What should the next session focus on?"
disable-model-invocation: true
---

Create a checkpoint for a future agent.

The checkpoint should contain the minimum information required to continue the work without reading this conversation.

Assume the future agent can inspect the codebase, tests, history, issues, ADRs, plans, and other project artifacts.

Do not duplicate information already captured elsewhere.

Prefer references to sources of truth over restating them.

If arguments were provided, prioritize information relevant to that future work.

Record only the delta introduced or clarified by this conversation.

Be concise.

A future agent should be able to continue the work from the checkpoint alone.
