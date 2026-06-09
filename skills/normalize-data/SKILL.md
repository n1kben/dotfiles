---
name: normalize-data
description: Normalizes a tangled or legacy field set into its independent axes — inventorying every field and the values it actually takes, factoring composite and product-coded fields into one axis per dimension, and turning every axis, every boolean included, into an explicit enum whose values and whose absence are each named. The decomposition pass that precedes building a data model. Trigger whenever someone faces an existing pile of fields, columns, flags, status codes, or enum values and wants them untangled, decomposed, or normalized; suspects one field encodes several independent things; asks what a boolean's false or null actually means; or needs the orthogonal dimensions behind a code surfaced — however loosely phrased.
---

Take a tangled field set — legacy columns, a status code, a pile of booleans — and reduce it to its independent **axes**, each a fully-named enum. This is the decomposition that precedes [data-modelling](../data-modelling/SKILL.md): normalize surfaces the real dimensions; modelling builds the graph from them. Work bottom-up from the values actually present, never the declared types. (This is decomposition to orthogonal axes, not relational normal forms.)

An **axis** is one independent dimension of variation: a single question whose answers are mutually exclusive. The whole job is to find the axes a field set conflates, give each its own field, and name every answer — absence among them.

Walk three stages in order.

**1 — Collect.** Inventory every field and the full set of values it actually takes — read the code, the rows, real samples; trust observed values over the declared type. A nullable column has `null` as one of its values; record it.

**2 — Factor.** Split every field that conflates more than one axis. Test a field by its values: take any two — can both hold at once, or does a single value answer two separate questions? A value like `leasing_tradein` answers _payment?_ and _trade-in?_ together — it is the product `payment × trade-in` and splits into one field per axis. A code whose values co-occur is a set of flags, not one choice — split it likewise. Only a field whose values are genuinely one-at-a-time stays single. Over-split rather than under: a real exclusivity collapses back into a sum later, in modelling; a buried axis stays buried.

**3 — Value.** Make every axis an explicit enum and name every value — absence included. A two-valued axis is still an enum, never a bare boolean: name both poles as domain facts (`Warranted | NotWarranted`), then decide what missing means — a real third value (`Unknown`, `NotApplicable`) or folded into a pole. Never leave `false` or `null` to mean whatever the reader guesses.

The output is a flat inventory of orthogonal axes, each a named enum — the irreducible facts [data-modelling](../data-modelling/SKILL.md) clusters into entities and values. Worked transforms in [EXAMPLES.md](./EXAMPLES.md).
