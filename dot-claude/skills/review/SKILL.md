---
name: review
description: Review whatever's in front of you — a diff, an implementation, a doc, a design, a plan — by fanning out subagents for the relevant angles (correctness/bugs, design/structure, and conformance to any governing docs when they exist), then synthesizing. Use when the user asks to "review", "review this", "review my changes", or to check something for problems before shipping.
---

<--- todo: Lets make it look relentlessly many times and then validate findings with subadjents to remove fluff. --->

# Review

**Goal:** find what's wrong or risky in the thing under review, and hand back one synthesized, severity-ordered report — not raw dumps.

Fan out independent subagents, one per angle that fits the material, so each looks with a clean context and a single focus. The angles that almost always apply: **correctness** (bugs, broken edge cases, wrong logic, dropped behavior) and **design** (structure, boundaries, naming, coupling, data modeling). Add a **conformance** angle whenever docs, conventions, or a spec govern the thing — checked against what those actually say, not invented rules. Drop or add angles to match what's being reviewed; a prose doc isn't reviewed like a state machine.

Why subagents rather than one pass: a single reviewer blends concerns and misses the ones it isn't currently thinking about. Separate remits surface separate classes of problem.

Synthesize into one report: deduped, roughly ordered by severity, each finding saying where, what's wrong, and why it matters. Separate clear defects from judgment calls — surface the latter for the user to decide rather than silently acting. Don't apply fixes unless asked.
