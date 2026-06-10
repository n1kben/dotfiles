---
name: normalize-data
description: Decompose a tangled field set into independent axes, each an explicit enum with absence named, then flatten every value into one list. Trigger when fields, flags, status codes, or enums need untangling or normalizing.
disable-model-invocation: true
---

Reduce a tangled field set to independent **axes** — each one question with mutually exclusive answers, made an explicit enum. Read the values actually present, not the declared types. The deliverable is a flat list of every value; the axes are the method that gets you there.

- **Collect** every field's real values; `null` counts.
- **Factor**: split any field answering more than one question (`leasing_tradein` = `payment × tradeIn`); leave genuinely one-at-a-time ones (`petrol | diesel | electric`).
- **Value**: name every value and absence — no bare bool (`inspected : Bool` → `Passed | Failed | NotInspected`).
- **Check**: a rule still spanning fields means over-split (collapse it) or a missing sum (`ByDealer DealerId | PrivateSale`).
- **List**: emit every named value from every axis — each absence included — as one flat, deduplicated list, with no axis structure carried over.
