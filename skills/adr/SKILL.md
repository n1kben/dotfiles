---
name: adr
description: Author and manage architecture decision records. Trigger whenever the user wants to record, document, or revisit an architecture or design decision — write an ADR, capture why a choice was made, log a trade-off, or supersede a past decision.
---

An ADR is written for a future developer looking at the code and wondering "why on earth did they do it this way?". Record _that_ a decision was made and _why_ — the forces that settled it, the alternatives weighed — and supersede rather than rewrite a record once the decision changes.

## Is an ADR warranted

Write one only when all three are true:

1. **Hard to reverse** — changing your mind later carries real cost.
2. **Surprising without context** — a future reader will wonder why it was done this way.
3. **The result of a real trade-off** — there were genuine alternatives and one was chosen for specific reasons.

If any is missing, skip it. When in doubt, don't manufacture a record — a log padded with non-decisions is one nobody trusts.

## Where it lives

ADRs live in `docs/adr/`, one file per decision, named `NNNN-slug.md` (e.g. `0007-postgres-for-write-model.md`). Numbering starts at `0001` and increments; numbers are never reused, even after a record is superseded.

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

Keep it to something read in no more than five minutes. If it is growing into a multi-page design doc, it is the wrong artefact — an ADR records the decision, not the full design.

## Status and immutability

Add a `Status` line (`proposed | accepted | deprecated | superseded by NNNN`) once decisions start getting revisited. A **proposed** record is freely editable; once **accepted** the body is immutable — fix typos and dead links, but never rewrite the conclusion. It is a snapshot of why the decision was right _then_.

When a decision changes, don't edit the accepted record. Write a new one, set the old record's status to `superseded by NNNN`, and link the two together. Mark a record **deprecated** instead when the decision no longer applies but nothing replaces it.
