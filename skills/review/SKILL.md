---
name: review
description: Surface the real flaws in whatever's in front of you. Use whenever the user wants something reviewed, critiqued, audited, torn apart, or checked for problems — code, prose, a plan, a design — however loosely phrased.
disable-model-invocation: true
---

Review by fanning out, never in one pass.

### 1. Scout what governs the material

Search wide for whatever sets the standard, wherever it lives — contributor and agent guides, READMEs and project docs, architecture decision records (ADRs), REVIEW.md files carrying review-specific instructions, style and convention guides, and the conventions of the surrounding code. Scanning the repo's markdown is the fastest way to surface most of these; the rest live in the code itself. Ground the review in how the material is meant to be done.

### 2. Fan out

Spawn independent subagents concurrently, one per angle that fits the material — correctness, design, and conformance whenever something governs the material, plus whatever else the material warrants such as security or bugs — each with a single remit, handing every one the scouted docs so each judges against the governing context rather than guesswork.

### 3. Refute

Hand every candidate finding to a fresh subagent whose job is to refute it against the material, and keep only what survives.

### 4. Synthesize

Fold the survivors into one severity-ordered report — where, what, and why for each. Don't apply fixes unless asked.

Subagents default to the smartest model available; when the user asks for fast mode, run them all on the fastest instead.
