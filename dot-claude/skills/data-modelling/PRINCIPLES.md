# Principles

Properties a good model satisfies — the bar a result clears, not moves you make (those live in the Procedure). Each is what a Tell diagnoses the absence of.

- **Minimise the source of truth — derive, don't duplicate.** Store the fewest facts you can; compute the rest. Every stored derivation is a second copy that can disagree with the first. Materialise one only when measured need forces a cache.
- **Make illegal states unrepresentable.** The shape should permit only what's true — a state the domain forbids should be impossible to write down, not caught by a validator after the fact. A shape that _can_ hold a forbidden state eventually will.
- **Identity only where it belongs.** An entity needs a nameable identity — what stays constant as its attributes change; can't name it, can't model it yet. But not everything has identity: a thing you'd never ask "which one?" of is a value, compared by contents. Don't force identity onto values.
- **Specificity over ambiguity.** A name must point at exactly one thing. "Order" points at nothing — a retail sale, a supplier purchase, and a sort order wear the same word. A noun you can't pin to one identity is a question you haven't answered.
- **What changes together is one unit.** Facts that must change together, or not at all, form one unit of consistency — keep its invariant in one place and reference other units by identity, not by embedding them.
