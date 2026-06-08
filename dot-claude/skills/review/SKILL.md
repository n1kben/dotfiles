---
name: review
description: Adversarial review of whatever's in front of you. Use when the user asks to review or critique something.
---

Before fanning out, scout for the docs that govern the work — CLAUDE.md, AGENTS.md, READMEs, contributing guides, ADRs, and the conventions of the surrounding code — and feed them to the subagents so conformance has a standard to check against rather than guesswork.

Review by fanning out, never in one pass. Spawn independent subagents, one per angle that fits the material — correctness, design, and conformance whenever something governs the work — each spawned concurrently with a single remit. Then make it adversarial: hand every candidate finding to a fresh subagent whose job is to refute it against the material, and keep only what survives.

Subagents default to the smartest model available; when the user asks for fast mode, run them all on the fastest instead. Synthesize the survivors into one severity-ordered report — where, what, and why for each — and don't apply fixes unless asked.
