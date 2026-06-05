# Interrogate — work the data tree

Goal: reduce every concept the domain hands you to the irreducible facts underneath it. This is first-principles thinking, but the bedrock is **facts** — you stop drilling when you hit something you cannot reconstruct from anything else.

Interview relentlessly, the way `grill-me` walks a design tree. Take one concept, walk down each branch, and resolve one node before moving to the next. For every question, propose your own best answer — don't just ask. When the answer is discoverable (in the codebase, the domain docs, the existing data), go find it instead of asking.

## The tree

- **Root** — the rich concept someone named: "an Order," "a subscription," "a booking."
- **Internal nodes** — derivations: anything computable from what sits below it.
- **Leaves** — irreducible facts: an identity, an attribute, a value, a time. You can't break them down further or rebuild them from anything else.

Working the tree means pushing every node downward until it's either a named derivation or a leaf fact. A node you can't push down and can't reconstruct is a **fact**. A node you _can_ reconstruct from its children is a **derivation** — label it and move on; it never joins the source of truth.

The payoff is the principle made concrete: the smaller the set of leaves, the smaller the source of truth. Every node you reclassify from fact to derivation is one less thing that can drift.

## At each node, ask

- **"What is this, specifically?"** Reject the generic noun. Keep qualifying until the name points at exactly one identity. If two answers fit, you've found two nodes, not one — split them.
- **"Is this a fact, or is it derived?"** Can you rebuild it from other facts? Then it's a derivation — cut it from the source of truth. Only what survives this question is a fact.
- **"What identifies it?"** If something stays constant while its attributes change, it's an entity — recurse into its attributes. If nothing identifies it and you'd never ask "which one?", it's a value — stop here.
- **"What's the smallest version of this fact?"** Break composites apart. A fact carrying several independent attributes is several facts.
- **"When could this be missing, and what would that mean?"** Unknown, not-applicable, and false are three different facts. Decide which now, not at encode time.
- **"Does this change for the same reason, under the same authority, as its sibling?"** If not, they belong to different identities — split the node.

## Stop when

- every leaf is a fact you cannot reconstruct from anything else,
- every internal node is a named derivation, not a stored copy,
- every name points at exactly one thing.

Then, and only then, move to [DEFINE.md](./DEFINE.md).
