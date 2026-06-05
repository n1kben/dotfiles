# Test — catch a model going wrong

Tells that a representation is fighting the domain. Each one points back to a missing identity, a derivation posing as a fact, or a name that hasn't been pinned down.

- **Duplicated state.** The same truth lives in two places — they will drift, and you'll write reconciliation code to paper over it. If one copy is computable from the other, it was never a second fact: delete it and derive it. Two writable copies of one truth is the most common modelling bug.
- **The generic noun.** A concept you can only name as "item," "data," "record," or "Order" is undefined — a bag standing in for the specific things inside it. The name should force the question: what, exactly, is in here? If you can't answer with one identity, you have more than one concept.
- **Similar vs. same.** A shared name or shape isn't shared identity. "Order" — a retail order, a purchase order, a sort order — is three identities under one word. Do they change for the same reasons, under the same authority? If not, split them.
- **The flag that grew up.** A yes/no that starts collecting a timestamp, an actor, or a reason was never a flag — it's an entity in disguise. Extract it.
- **Count the states.** A representation can express the product of its parts' possibilities — three independent yes/nos = eight combinations. Compare that to how many the domain actually allows. Every excess is a state you can write down but that should never occur. Tighten the shape until the two counts match.
- **Things that travel together are a concept.** The same `(latitude, longitude)` in five places, an opaque `options` bag, a trio of values always passed as a unit — a clump that moves together is an unnamed concept. Name it, and everywhere that passed the loose bag gets clearer.
- **The snapshot test.** Would you rather freeze this than overwrite it? Then it has identity, and editing it in place is a bug. The freeze-point is an event; a snapshot is just an immutable fact, while the editable version is only "current state."
- **Absence is ambiguous.** A missing value can mean unknown, not-applicable, or false. Decide which — and if more than one is possible, the model has to say which.
- **The load-bearing cache.** If anything but the deriver writes to something you call derived, it's a source of truth wearing a cache's clothes. Either make it a real fact or stop writing to it.
