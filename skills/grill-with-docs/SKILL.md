---
name: grill-with-docs
description: Grilling session that challenges your plan against the project's documented model, sharpens terminology, and records what settles in CONTEXT.md and docs/adr/ as decisions crystallise. Use when the user wants to stress-test a plan against their project's existing language and recorded decisions.
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer. Ask one at a time, waiting for my answer before the next.

If a question can be answered by exploring the codebase, explore it instead of asking. Keep it conversational, short, and to the point.

What sets this session apart from a plain grilling is that it is anchored to the project's *documented* model. Before grilling, surface that model and read it — the domain glossary (`CONTEXT.md`, or the contexts a `CONTEXT-MAP.md` points to) and the records in `docs/adr/` — then hold the conversation to it. Three moments deserve a hard stop:

- **A term clashes with the documented language** — I reach for a word the glossary defines differently, or two words for one concept. Name the clash and settle which term wins.
- **A term is fuzzy or overloaded** — "account", "cancel", "owner". Make me say which precise thing I mean.
- **Code contradicts what I claim** — surface the disagreement rather than letting it stand.

Capture what settles the moment it crystallises — don't batch it for the end. When the language sharpens or a term lands, record it with the **ubiquitous-language** skill, which owns the glossary's format and where it lives. When a decision settles that is hard to reverse, surprising without context, and the product of a real trade-off, record it with the **adr** skill. Naming either skill here is the cue to use it — lean on it for the how, and keep grilling.
