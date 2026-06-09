---
name: adr
description: Author and manage architecture decision records — one record per significant, hard-to-reverse decision, capturing the forces that settled it and the alternatives weighed, superseded rather than rewritten when it changes. Trigger whenever the user wants to record, document, or revisit an architecture or design decision — write an ADR, capture why a choice was made, log a trade-off, or supersede a past decision — however loosely phrased.
---

An ADR is written for a future developer looking at the code and wondering "why on earth did they do it this way?". Record _that_ a decision was made and _why_ — the forces that settled it, the alternatives weighed — and supersede rather than rewrite a record once the decision changes.

## Is an ADR warranted

Write one only when all three are true:

1. **Hard to reverse** — changing your mind later carries real cost.
2. **Surprising without context** — a future reader will wonder why it was done this way.
3. **The result of a real trade-off** — there were genuine alternatives and one was chosen for specific reasons.

If any is missing, skip it. When in doubt, don't manufacture a record — a log padded with non-decisions is one nobody trusts.

What typically qualifies: architectural shape (a monorepo, an event-sourced write model), technology choices that carry lock-in (database, message bus, auth provider — not every library), integration patterns between contexts, boundary and ownership decisions (the explicit _no_s matter as much as the _yes_es), deliberate deviations from the obvious path, and constraints invisible in the code (compliance, latency budgets, contractual limits).

## Where it lives

ADRs live in `docs/adr/`, one file per decision, named `NNNN-slug.md` (e.g. `0007-postgres-for-write-model.md`). Scan the directory for the highest number and increment by one; numbers are monotonic and never reused, even after a record is superseded. Create `docs/adr/` lazily — only when the first record is needed.

If a `CONTEXT-MAP.md` at the repo root signals multiple contexts, each may keep its own `docs/adr/`; place the record with the context it governs and reserve the root `docs/adr/` for system-wide decisions. Otherwise a single root `docs/adr/` holds everything.

## Writing it

Scale the record to the decision. The floor is three sections; reach past them only when the extra earns its place.

```md
# {Short noun-phrase title naming the decision}

## Context
{The forces at play — technical, organisational, constraints — stated as neutral facts.}

## Decision
We will {the choice, in active voice}.

## Consequences
{What becomes true as a result — positive, negative, and neutral.}
```

- **Context** describes the situation, not the solution. State the competing pressures as facts a reasonable person would agree with before knowing the outcome; if any option would obviously be fine, the real forces aren't on the page yet.
- **Decision** is one committed sentence in active voice — "We will…", not "we should consider". The phrasing signals a choice was made, not a discussion held.
- **Consequences** lists _all_ of them, not just the wins. Recording the costs and the things now made harder is what makes the log trustworthy; a record with only upsides reads as a sales pitch.
- **Considered Options** — add this section only when the rejected alternatives are worth remembering. List the serious ones with why each lost, so nobody re-proposes the tempting wrong choice in six months. A straw-man alternative listed only to flatter the chosen one is worse than omitting the section.

Keep it to something written in 10–30 minutes and read in five. If it is growing into a multi-page design doc, it is the wrong artefact — an ADR records the decision, not the full design.

## Status and immutability

A `Status` line (`proposed | accepted | deprecated | superseded by NNNN`) is worth adding once decisions get revisited. While **proposed**, the record is freely editable. Once **accepted**, the body is immutable: fix typos and dead links, but never rewrite the conclusion or consequences — the record is a snapshot of why the decision was right _then_. Mark a record **deprecated** when the decision no longer applies but nothing replaces it; use **superseded** when a new record takes its place.

When a recorded decision changes, find the existing record first rather than starting fresh — the whole point is to replace it in place, not to leave two records disagreeing. Don't edit the accepted record. Write a new one, set the old record's status to `superseded by NNNN`, and link the new record back to the one it replaces. A silently-stale decision log is worse than none.
