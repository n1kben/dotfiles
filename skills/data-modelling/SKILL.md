---
name: data-modelling
description: Designs and critiques how information is represented — reducing concepts to their irreducible facts, separating fact from derived, catching models tangled with flags and statuses, and translating the result into a database schema, type system, application state, API payload, event log, form, or spreadsheet. Trigger whenever someone designs, reviews, or refactors a data model, schema, type, table, or state shape; asks what fields, columns, tables, or enums a thing needs; weighs whether something is one entity or two, a flag or its own thing, stored or computed; or senses a representation is tangled, duplicated, or hard to change — however loosely phrased.
disable-model-invocation: true
---

Resolve the user's model bottom-up — find the **facts**, build the graph from them, render the types last. Mine the code and domain yourself: state each fact you can already infer and move on, reserving questions for what's genuinely open, asked one at a time, each with a recommended answer.

**Gather every fact first.** Test each candidate, _true-or-computed?_, cutting all derivations — concepts, totals, and statuses are computed, never stored — until only irreducible truths remain. **Then build the graph:** ask each fact _identity-or-value?_, clustering them into entities, composite values, and the references between. **Then render the [types](./TYPES.md)** from the settled graph — mechanical once it stands.

Check each node against the [tells](./TELLS.md) throughout; [vocabulary](./VOCABULARY.md) pins the words, [principles](./PRINCIPLES.md) hold.
