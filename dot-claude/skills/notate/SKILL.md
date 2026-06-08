---
name: notate
description: Communicate the shape of a thing — a design, an existing system, a flow, an argument, a decision — as structure rendered in its own native notation, so boundaries, flows, and gaps read at a glance instead of being buried in prose. Trigger when the user wants the shape of something laid out as structure rather than paragraphs — says to notate, outline, sketch, diagram, map it out, or show the shape of it — however loosely phrased.
---

Re-represent the thing in the notation it already has, so its shape reads at a glance. Prose and generic bullet-lists flatten structure; a paragraph hides which premise is load-bearing, which transition is illegal, which dependency points the wrong way. Pick the notation native to what you're showing and let the structure carry the meaning — not boxes-and-arrows of your own invention.

**The trigger is a hidden shape.** Reach for this when prose is concealing a structure: a boundary, a flow, a hierarchy, a cycle, a set of relations, a space of options. If there is no hidden shape — the value is in voice, nuance, or one irreducible argument that won't decompose — leave it as prose. Forcing structure onto shapeless content is a tax, not a gift.

**Pick the notation that exposes what you care about.** Non-exhaustive — render in whatever notation the dimension already has:

- *Boundaries & contracts* — type/interface signatures, API endpoint maps, request/response shapes, DB table definitions, GraphQL schemas.
- *Flow & control* — call graph, sequence diagram, request pipeline, UX flow (user action → behaviour → layer → file), pseudocode.
- *Structure & containment* — component tree, directory tree, dependency graph, ER diagram, taxonomy.
- *States & transitions* — state machine, lifecycle/cycle, and the rules a diagram can't encode (invariants).
- *Reasoning & choice* — argument map, decision/tradeoff matrix, causal loop, 2×2, payoff matrix, RACI.

Reach past this list whenever a notation fits better. The list is illustration, not menu.

**The hole is often the payload.** The transition you *don't* draw is the illegal one; the empty cell is the finding; the orphan node with no inbound edge is the dead code; the unsupported premise is the weak point. Make the absence legible rather than papering over it.

**When the delta is the point, draw two structures side by side** — production vs test, before vs after, plan A vs B — aligned so the eye subtracts and the diff *is* the boundary.

Annotate each node with the facts that decide it — where it lives, what it owns, where the swap or transition happens — and cut any notation that doesn't make a boundary or flow legible at a glance. Keep it to one page. Lead with what matters most. Leave holes where things are undecided — a hole names an open question, not a faked answer.

For the layouts whose form is non-obvious — the call graph and component tree — copy the specimens in [EXAMPLES.md](./EXAMPLES.md).
