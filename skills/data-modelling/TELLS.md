# Tells

Smells that reveal a model fighting the domain. Most are the contrapositive of a principle — named in brackets.

- **Duplicated state** _(minimise source of truth)_ — one truth writable in two places; they drift. Derive one from the other.
- **Impossible states** _(illegal states unrepresentable)_ — a shape admits the product of its parts (three booleans = eight); every combination the domain forbids is a latent bug. Shrink until expressible equals legal.
- **Similar vs. same** _(specificity)_ — a shared name or shape isn't shared identity. Do these change for the same reasons, under the same authority? If not, they're two things wearing one word — split them.
- **The flag that grew up** _(identity)_ — a boolean collecting a timestamp, actor, or reason was always an entity. Extract it.
- **The relationship that grew up** _(identity)_ — a link that starts carrying its own attributes (a `role`, a `since`) is an entity, not a foreign key. Give it identity.
- **Clumps that travel together** _(specificity)_ — the same `(lat, lng)` in five signatures is an unnamed value. Name it.
- **The load-bearing cache** _(minimise source of truth)_ — anything but the deriver writing to a "derived" value means it's a source of truth in disguise.
- **Edited snapshots** — would you rather freeze it than overwrite it? It's an event (an immutable fact), not current state.
- **Ambiguous absence** — missing means unknown, not-applicable, or false. Pick one, or model the difference.
