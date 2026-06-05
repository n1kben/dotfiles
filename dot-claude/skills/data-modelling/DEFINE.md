# Define — name and classify the facts

You've worked the tree ([INTERROGATE.md](./INTERROGATE.md)); the facts are on the table. Two jobs now: name each concept so it points at exactly one thing, and classify it.

## Name in the domain's language

- **One name, one identity.** Name each concept from inside its context, specific enough that it can't be confused with a neighbour. The same word holds different identities in different contexts — sales' "customer" isn't support's. If a name needs a qualifier to be unambiguous, the qualifier is part of the name.
- **Distrust the bare noun.** A concept you can only name generically — "item," "record," "data," "Order" — isn't defined yet; it's a bag standing in for the specific things inside it. Qualify it or split it until each piece earns a name that points at one identity.

## Classify each thing

- **Entity or value?** A thing with identity that persists while its attributes change is an **entity** — its own concept. A thing you'd never ask "which one?" of is a **value** — immutable, compared by its contents, equal-attributes-mean-same-thing. A value is more than a bare label: a constrained value (an `EmailAddress`) can't hold the garbage a raw string can.
- **Fact or derivation?** Only facts are authoritative. A derivation — a total, a live balance, the rich concept itself — is recomputed, never stored as truth. Materialize a derivation only when a measured need forces it, and then it's a cache, not a source. When in doubt, it's a derivation: the source of truth should be the smallest set of facts that everything else falls out of.
- **Entity, not flag.** A thing with its own identity is its own concept, not a boolean on another. A cancellation isn't a `cancelled` flag — it's its own thing, with its own who, when, and why.
- **Effects aren't facts.** A clock reading, a live balance, today's exchange rate — each depends on _when_ or _where_ you looked. Capture the result as a timestamped fact; keep the reading itself at the edge.
- **Commit late.** Bind concepts as questions asked over facts, so "are these two the same thing?" stays a reversible decision rather than one baked into the shape.
