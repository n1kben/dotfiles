# Encode — translate the model into a medium

Only now answer "what fields, tables, types, columns, forms?" Once identity and derivation are settled, translation is mechanical:

- identity → a **record** (a row, an object, a sheet entry)
- "or", mutually exclusive cases → a **choice** between shapes
- "and", things that coexist → a **grouping**
- "many" → a **collection**

**The one job of any representation: permit only what the domain permits.** A forbidden state shouldn't merely be flagged invalid after the fact — it should be impossible to express in the first place. This holds in every medium; only the mechanism changes.

## Make illegal states unexpressible

- **Push constraints into the shape, not into a checker.** "These never coexist," "this requires that" — encode it structurally, not as a validation rule or a comment. A shape that _can_ hold a forbidden state eventually holds one.
- **"Or" is a choice, not a pile of optional fields.** Mutually exclusive cases become one tagged choice, each case carrying only its own data — not one record with half its fields blank. A record full of "fill this in only when…" fields is a choice that lost its tag.
- **A lifecycle is a sequence of shapes, not a status label.** A single status field lets every transition look legal. Give each state its own shape carrying only the data that state has, and make each transition a step from one shape to the next. Then "refund before paid" can't be expressed, not merely rejected.
- **Optionality and cardinality are claims.** Each optional field blurs unknown / not-applicable / not-yet — pick one meaning and represent the others as distinct cases. One-vs-many and zero-or-one-vs-exactly-one assert something about the domain; guess wrong and the shape hides a bug.

## A valid value should be unforgeable

- **Route construction through one gate.** A "valid" value only stays valid if there's a single way to make it that can fail. Hide the raw way of building it; construct only through something that returns success-or-error. Then holding the value _is_ proof it's valid, and no later reader re-checks. Every extra way to build it is a hole in the guarantee.

## How it lands per medium

The principles above are the same everywhere. The mechanism differs:

- **Types / code.** "Unexpressible" means "won't compile." Sums (tagged unions) for "or," records for "and," a private constructor plus a smart constructor for the gate, a distinct type per lifecycle state so transitions are functions between them.
- **Relational tables.** Identity is the key — key each row by what names the thing in the domain; reach for a surrogate id only when nothing names it stably. A choice ("or") has no native table: a column asserts its value holds for _every_ row, so variant attributes become nullable columns where `NULL` conflates "other variant" with "value absent." Keep one table with a `CHECK` tying tag to columns only when each variant's columns are mandatory within that variant; if a value could also be genuinely absent within a variant, the ambiguity is unfixable — give the variant its own table.
- **Documents / wire payloads.** A flat JSON payload is a _view_ of the facts for transport, never the source. Parse it into the precise model at the boundary; don't let the wire shape leak inward.
- **Forms / spreadsheets / no-code.** The same moves without a compiler to enforce them: a column meaningful for only some rows is a hidden "or" — split the sheet or the form. Conditional "show this field when…" sections are the cases of a choice. One row should be one fact; a row that means different things depending on a "type" column is a choice begging to be separated.

## Across boundaries

- **Parse once, at the edge.** Turn shapeless input into the precise model at the boundary and keep it precise inward. Loose shapes threaded through the core rot it.
- **Same facts, layered encodings.** The storage shape, the working shape your logic reasons over, and the wire shape are three renderings of one truth. Each serves its layer; none is the source for another. Don't let storage's shape or the payload's shape dictate how the core thinks.
- **A model holds only in its context.** The same word names a different concept across contexts — sales' "customer" isn't support's "customer." Don't force one shared model across the boundary; translate at it. Draw the consistency boundary around facts that must change together, and reference everything else by identity rather than embedding it.
