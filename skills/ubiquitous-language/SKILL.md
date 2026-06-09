---
name: ubiquitous-language
description: Author and manage the ubiquitous language of a codebase — one precise, opinionated definition per domain term in CONTEXT.md, and a map of the bounded contexts and how they relate once a system has more than one. Trigger whenever the user wants to record, sharpen, or settle domain vocabulary — define a term, pick the word for a concept, document a bounded context or context map, or reconcile language that has drifted — however loosely phrased.
---

`CONTEXT.md` is the project's ubiquitous language: the one place that says what each domain word means, so that the people, the docs, and the code all use it the same way. Capture each domain term as one precise, opinionated definition, and collapse the synonyms competing with it. You reach for this whether you sat down to write the glossary deliberately or caught a term drifting mid-conversation — a grilling session, a design review, an architecture pass surface most entries reactively. Either way the discipline is identical, and it is the whole job: `CONTEXT.md` is a glossary and nothing else — not a spec, not a design doc, not a scratchpad for decisions. It serves whoever — human or agent — later meets a word like "settlement" or "cancellation" and needs to know precisely what it refers to here, because the same word means something else one project over. Decisions that need a "why" belong in an ADR; `CONTEXT.md` records only what a word _means_.

## What belongs in it

A term earns a place only when it is **specific to this domain** and **carries a meaning a reader could get wrong**. The test before adding anything: is this a concept unique to this context, or a general programming idea the project happens to use? Timeouts, retries, error types, generic utility patterns — out, however heavily used. "Settlement", "Consignment", "Eligibility window" — in, because they mean something particular here.

Three disciplines keep it trustworthy:

- **Be opinionated.** When several words circulate for one concept, pick the best one and list the rest under `_Avoid_`. The value is in collapsing synonyms to a single canonical term — a glossary that blesses three words for the same thing has resolved nothing.
- **Define what it _is_, not what it does.** One or two sentences. "An Invoice is a request for payment sent after delivery", not a paragraph on how invoices are generated. Behaviour and mechanism are implementation; they drift, and they don't belong here.
- **Keep it free of implementation.** No class names, no table names, no "stored as", no API shapes. If a line would change when you refactored without changing what the word means, it is in the wrong file.

## Where it lives

Most repos have a single context: one `CONTEXT.md` at the root.

```
/
├── CONTEXT.md
└── src/
```

When a system spans **more than one** context, a `CONTEXT-MAP.md` at the root lists them and points to where each lives, and each context keeps its own `CONTEXT.md` beside its code:

```
/
├── CONTEXT-MAP.md
└── src/
    ├── ordering/   └── CONTEXT.md
    └── billing/    └── CONTEXT.md
```

Infer the structure: a `CONTEXT-MAP.md` means multiple contexts — read it to find them; a lone root `CONTEXT.md` means one. Create files lazily — bring `CONTEXT.md` into being only when the first term is worth recording, and promote to a `CONTEXT-MAP.md` only when a genuine second context appears. With multiple contexts, work out which one the current term belongs to before writing; if it is unclear, ask.

## Writing the glossary

```md
# {Context Name}

{One or two sentences: what this context is and why it exists.}

## Language

**Order**:
A customer's request to buy, once submitted.
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organisation that places orders.
_Avoid_: Client, buyer, account
```

Keep definitions tight and the list scannable. Group terms under `##` subheadings when natural clusters emerge; a flat list is fine when they all belong to one cohesive area. The point of `_Avoid_` is not to shame synonyms but to redirect them — when someone reaches for "buyer", the line tells them the word here is "Customer".

## When a system has more than one context

A **bounded context** is the boundary within which a term has exactly one meaning. The signal to split is linguistic, not organisational: when the _same word_ carries two genuinely different meanings ("Order" means a basket in one area and a fulfilment job in another), or a term central to one area is meaningless in another, you are looking at two contexts. Split where the language forks — not along team or folder lines for their own sake — and resist over-splitting: two areas that share one consistent vocabulary are one context.

`CONTEXT-MAP.md` records the contexts and, crucially, how they relate — the relationships are the part the code can't tell you:

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md) — generates invoices and processes payments
- [Fulfillment](./src/fulfillment/CONTEXT.md) — manages warehouse picking and shipping

## Relationships

- **Ordering → Fulfillment** (customer/supplier): Ordering emits `OrderPlaced`; Fulfillment consumes it to start picking
- **Fulfillment → Billing** (published language): Fulfillment publishes `ShipmentDispatched`; Billing consumes it to invoice
- **Ordering ↔ Billing** (shared kernel): a shared `CustomerId` and `Money` both teams own together
```

Naming the integration pattern on a relationship is optional but sharpens it. The vocabulary, by who shapes the language across the boundary:

- **Shared kernel** — a small slice of model both contexts own jointly and change only by agreement.
- **Customer/supplier** — the downstream context can negotiate what the upstream provides and when.
- **Conformist** — the downstream adopts the upstream's language wholesale, with no translation and no say.
- **Anticorruption layer** — the downstream translates at the boundary to keep the upstream's model out of its own.
- **Open-host service / published language** — the upstream exposes a documented contract many can consume.
- **Partnership** — two contexts succeed or fail together and coordinate as equals.
- **Separate ways** — no integration; the contexts deliberately don't talk.

## Keeping it alive

`CONTEXT.md` is a living document, not a snapshot — it is right to edit it whenever the language sharpens, unlike an ADR. Capture terms inline as they settle rather than batching them. When a proposed term conflicts with one already on the page, resolve it on the spot — surface the clash, pick the survivor, fold the other into `_Avoid_` — rather than letting two definitions of one word coexist, which defeats the entire purpose. When a term is renamed, replace the definition in place and demote the old word to `_Avoid_` so the redirect survives the change. Keep the file tight: a glossary nobody can scan in a minute is one nobody consults.
