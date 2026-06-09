# Vocabulary

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
