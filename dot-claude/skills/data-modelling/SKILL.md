---
name: data-modelling
description: Use when designing or critiquing how information is represented — in a database, a type system, application state, an API payload, an event log, a form, a spreadsheet, anything that holds data. Covers reducing concepts to their irreducible facts, deciding what's a fact versus what's derived, catching a model that's tangled or full of flags, and translating it into a concrete medium. Trigger whenever someone reaches for a data model, schema, or structure, asks what fields or tables a thing needs, or senses a representation is hard to change — however loosely phrased.
---

# Data Modelling

Design or critique how information is represented, in any medium. Work from first principles — but the principles are **facts**: reduce every concept to the irreducible facts underneath it, then build the model back up from those. The order is fixed — find the facts, define the model, test it, encode it. Jumping straight to "what tables or types?" is the mistake.

## Glossary

Use these terms exactly.

- **Fact** — the irreducible unit of truth: an _identity_, an _attribute_ + _value_, a _time_, and whether it's _asserted or retracted_. You cannot reconstruct a fact from other facts. Facts are the leaves of the data tree.
- **Derivation** — anything computable from facts: a total, a rollup, a current status, the rich `Order` concept itself. Recomputed on demand, never stored as truth.
- **Source of truth** — the minimal set of facts every derivation is built from. Keep it as small as you can.
- **Identity** — what stays the same while attributes change; what you point at to say "that one." The spine of every entity.
- **Value** — a thing with no identity: immutable, compared by its contents, interchangeable when equal (money, a date range, an email address).
- **Entity** — a thing with its own identity. Its own concept, never a flag on something else.
- **Effect** — a reading that depends on _when_ or _where_ you look (a clock, a live balance, a fetched row). It _produces_ a fact; it isn't one.
- **Data tree** — a concept decomposed toward its facts: the rich concept at the root, derivations as internal nodes, irreducible facts as the leaves.

## Principles

- **Minimize the source of truth — derive, don't duplicate.** Store the fewest facts you can and compute everything else. Every stored derivation is a second copy that can disagree with the first. If it can be reconstructed from facts, it is not a fact — keep it only when a measured need forces a cache, and then it's a cache, not a source.
- **Specificity over ambiguity.** A name must point at exactly one thing. "Order" points at nothing — a retail sale, a supplier purchase, and a sort order wear the same word. Qualify every noun down to a single identity; a noun you can't pin down is a question you haven't answered.
- **Identity first.** If you can't name what identifies a thing — what stays constant as everything about it changes — you can't model it yet. Settle identity before anything else.

## Process

Run these in order; each links a reference with the detail.

1. **Interrogate — work the data tree.** [INTERROGATE.md](./INTERROGATE.md). Take each concept and drill down relentlessly, one branch at a time, until every leaf is an irreducible fact. Resolve ambiguity as you go, reject generic nouns, separate facts from derivations. This is the bulk of the work.
2. **Define.** [DEFINE.md](./DEFINE.md). Name each concept in the domain's language — specific and unambiguous — and classify it: fact or derivation, identity or value, entity or flag.
3. **Test.** [TEST.md](./TEST.md). Run the tells that a model is fighting the domain: duplicated state, generic nouns, grown-up flags, states that can't legally occur.
4. **Encode.** [ENCODE.md](./ENCODE.md). Only now translate into a medium — types, tables, a document, a form — making illegal states impossible to express.
