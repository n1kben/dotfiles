---
name: data-modelling
description: Use when designing or critiquing how information is represented — in a database, a type system, application state, an API payload, an event log, a form, a spreadsheet, anything that holds data. Covers reducing concepts to their irreducible facts, deciding what's a fact versus what's derived, catching a model that's tangled or full of flags, and translating it into a concrete medium. Trigger whenever someone reaches for a data model, schema, or structure, asks what fields or tables a thing needs, or senses a representation is hard to change — however loosely phrased.
---

# Data Modelling

A model is a set of **facts**; everything above them — every concept, total, and status — is **derived**. Store a derivation as if it were a fact and it drifts, contradicts, and rots. So the question is never "what fields or tables?" — it's "what is irreducibly true here?" Settle that first; the representation is a mechanical translation that comes last, into any medium.

Work the **Procedure** to build the model. Hold the **Principles** as you go, reach for **Tells** when something smells off, and consult **Encoding** only once the facts are settled. **Vocabulary** pins the words the rest of this uses.

## Vocabulary

Use these terms exactly.

- **Fact** — the irreducible unit of truth: an _identity_, an _attribute_ + _value_, a _time_, asserted or retracted. Can't be reconstructed from other facts, and asserts one attribute of one identity at one time — if you can retract half of it independently, it's two facts. The leaves of the data tree.
- **Derivation** (a _view_ over facts) — anything computable from facts: a total, a current status, the rich `Order` concept itself. Recomputed on demand, never stored as truth.
- **Source of truth** — the minimal set of facts every derivation is built from.
- **Identity** — what stays the same while attributes change; what you point at to say "that one."
- **Value** — a thing with no identity: immutable, compared by its contents, interchangeable when equal (money, an email address). May be atomic or composite — a date range is two dates, an address several fields — but it's still compared whole, by contents, never by identity.
- **Entity** — a thing with its own identity; its own concept, never a flag on another.
- **Effect** — a reading that depends on _when_ or _where_ you look (a clock, a live balance, a fetched row). It _produces_ a fact; it isn't one.
- **Unit of consistency** (an _aggregate_) — a set of facts that must change together or not at all; its invariant is enforced in one place, and other units reference it by identity, not by embedding.
- **Data tree** — a concept decomposed toward its facts: the rich concept at the root, derivations as branches, irreducible facts as the leaves.

## Principles

- **Minimise the source of truth — derive, don't duplicate.** Store the fewest facts you can; compute the rest. Every stored derivation is a second copy that can disagree with the first. Materialise one only when measured need forces a cache.
- **Make illegal states unrepresentable.** The shape should permit only what's true — a state the domain forbids should be impossible to write down, not caught by a validator after the fact. A shape that _can_ hold a forbidden state eventually will.
- **Identity only where it belongs.** An entity needs a nameable identity — what stays constant as its attributes change; can't name it, can't model it yet. But not everything has identity: a thing you'd never ask "which one?" of is a value, compared by contents. Don't force identity onto values.
- **Specificity over ambiguity.** A name must point at exactly one thing. "Order" points at nothing — a retail sale, a supplier purchase, and a sort order wear the same word. A noun you can't pin to one identity is a question you haven't answered.
- **What changes together is one unit.** Facts that must change together, or not at all, form one unit of consistency — keep its invariant in one place and reference other units by identity, not by embedding them.
- **Two clocks, not one.** A fact carries two times — when it became true in the world and when the system learned it. Keep them separate, or you can't backdate a correction or replay history as it was known at a past moment.

## Procedure

Reduce every concept to the irreducible facts underneath it — first principles, where the bedrock is facts. Walk the data tree one branch at a time, proposing your own answers and exploring the domain or code for them rather than asking when you can. Classify each node on two axes:

- **True or computed?** If you can rebuild it from other facts, it's a derivation — name it and cut it from the source of truth. Only what survives is a fact.
- **Identity or value?** Something that stays itself as its attributes change has identity → an **entity**; recurse into its attributes. Something compared only by its contents is a **value** — and a value can be composite (a date range is two dates), so decompose it too; you just compare it whole, never by identity.

Reject generic nouns as you go — keep qualifying until each name points at one thing. And bind sameness late: keep "are these two the same?" a question over facts, so it stays reversible rather than frozen into the shape. Done when every leaf is an irreducible fact or atomic value, every branch a named derivation or composite, every name specific.

This isn't a clean pass. As you walk, check branches against the **Tells** below; once the facts hold still, turn to **Encoding**. Both are reference shelves, not later phases — revisit them throughout.

## Tells

Smells that reveal a model fighting the domain. Most are the contrapositive of a principle — named in brackets.

- **Duplicated state** _(minimise source of truth)_ — one truth writable in two places; they drift. Derive one from the other.
- **Impossible states** _(illegal states unrepresentable)_ — a shape admits the product of its parts (three booleans = eight); every combination the domain forbids is a latent bug. Shrink until expressible equals legal.
- **Similar vs. same** _(specificity)_ — a shared name or shape isn't shared identity. Do these change for the same reasons, under the same authority? If not, they're two things wearing one word — split them.
- **The flag that grew up** _(identity)_ — a boolean collecting a timestamp, actor, or reason was always an entity. Extract it.
- **The relationship that grew up** _(identity)_ — a link that starts carrying its own attributes (a `role`, a `since`) is an entity in its own right, not a foreign key. Give it identity.
- **Clumps that travel together** _(specificity)_ — the same `(lat, lng)` in five signatures is an unnamed value. Name it.
- **The load-bearing cache** _(minimise source of truth)_ — anything but the deriver writing to a "derived" value means it's a source of truth in disguise.
- **Edited snapshots** — would you rather freeze it than overwrite it? It's an event (an immutable fact), not current state.
- **Ambiguous absence** — missing means unknown, not-applicable, or false. Pick one, or model the difference.

## Encoding

Mechanical once the facts are settled: identity → a record, "or" → a choice between shapes, "and" → a grouping, "many" → a collection. The shape has one job: **permit only what's true** — a forbidden state should be impossible to write, not flagged after.

- **"Or" is a tagged choice**, each case owning its fields — not one record with half its columns blank.
- **A lifecycle is a sequence of shapes** with transitions between them, not a status field every transition can scribble.
- **Optionality and cardinality are claims** — each "optional" must resolve to one of unknown / N-A / not-yet; one-vs-many asserts something true.
- **Construct through one fallible gate**, so that holding the value proves it's valid.

Same facts render many ways — storage, logic, wire — each a view, none the source. Parse shapeless input into the precise shape once, at the edge. A model holds only in its context: sales' "customer" isn't support's — translate at the boundary.

**Per medium**, "permit only what's true" lands differently:

- **Types** — _won't compile_: tagged unions for "or", records for "and", a private + smart constructor for the gate, a distinct type per lifecycle state.
- **Tables** — identity is the key; a surrogate id only when nothing names the thing stably. A choice has no native table: variant attributes become nullable columns where `NULL` conflates "other variant" with "value absent". Keep one table + a `CHECK` only when each variant's columns are mandatory within it; otherwise give the variant its own table.
- **Documents / wire** — a flat payload is a view for transport; parse it into the precise shape at the boundary, don't let it leak inward.
- **Forms / spreadsheets** — a column meaningful for only some rows is a hidden "or"; conditional "show when…" fields are the cases of a choice; one row = one fact.
