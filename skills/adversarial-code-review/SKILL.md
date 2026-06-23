---
name: adversarial-code-review
description: Review a code change against the evidence, constraints, decisions, and conventions that govern it, then subject every finding to adversarial challenge.
disable-model-invocation: true
---

Review the change against evidence, not taste.

## Establish the Review Surface

Determine what is being reviewed and gather all material relevant to the change.

Understand what changed and why before evaluating how it was implemented.

Use subagents where helpful to gather and summarize context without polluting the main review.

Review the change first. Expand outward only as needed.

## Gather Evidence

Use subagents to gather evidence for how this problem should be solved:

- project instructions, docs, and ADRs
- surrounding code and prior implementations
- framework, library, and platform documentation
- domain-specific constraints

Return only evidence relevant to the review.

Use precedent as evidence, not authority.

Look for existing solutions before accepting new ones.

Prefer current evidence over historical documentation when they conflict.

## Identify Risks

Use independent subagents to identify the constraints, assumptions, and risks introduced by the change.

Always review for:

- correctness
- consistency with the codebase

Add review angles based on the risks introduced by the change, such as security, performance, reliability, migrations, compatibility, or operational impact.

Do not assume the implemented solution is the correct solution merely because it was implemented.

## Run the Engine

Invoke `/adversarial-review` with:

- the review surface
- gathered evidence
- identified risks
- review angles derived from those risks
