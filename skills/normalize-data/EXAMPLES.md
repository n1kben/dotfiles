# Worked transforms

Four normalizations and one deliberate non-split. Syntax is Elm, matching `data-modelling`.

## Product-coded enum → two axes

A single code whose values are a Cartesian product of independent questions.

```
dealType : "leasing_tradein" | "leasing" | "cash_tradein" | "cash"
```

Each value answers _payment?_ **and** _trade-in?_ at once. Four values = the 2×2 grid of `payment × tradeIn`. Factor:

```elm
payment : Leasing | Cash
tradeIn : WithTradeIn | NoTradeIn
```

The code never carried a fifth, exclusive option — it was two yes/no axes spelled out longhand. Splitting also kills the impossible-state risk of a future `"leasing_cash"`.

## Flag-set wearing an enum → one axis each

```
badge : "reduced" | "popular" | "new"
```

Take two: a listing can be `reduced` **and** `popular` at once — they co-occur, so this is not one choice. Each is its own axis:

```elm
price   : Reduced | FullPrice
listing : NewStock | UsedStock
```

`popular` survives the split as a suspected **derivation** (computed from views, not asserted) — carry it forward to modelling's _true-or-computed?_ test rather than minting an axis for it.

## Boolean → enum with absence named

```
inspected : Bool
```

`false` is doing two jobs: cars examined and rejected, and cars never examined at all. Name the poles, then place absence:

```elm
inspection : Passed | Failed | NotInspected
```

If "not yet inspected" differs from "inspection not offered for this model," that's a fourth value (`NotOffered`) or a second axis (`inspectionOffered : Offered | NotOffered`) — the absence forced the question. A bool would have hidden it.

## Nullable foreign key → presence axis + value

```
soldByDealerId : DealerId?
```

`null` conflates two facts: _sold by a dealer at all?_ and _which one?_. Separate them:

```elm
soldBy : ByDealer DealerId | PrivateSale
```

Now `null` has a name (`PrivateSale`), and the id only exists where it is meaningful — an illegal "dealer sale with no dealer" can't be written down.

## Do not split — a genuine single axis

```
fuel : "petrol" | "diesel" | "electric"
```

Take any two: a car is exactly one. The values are truly one-at-a-time — one axis, leave it. Factoring is for fields that conflate *independent* questions; an enum that is already one question stays a clean enum. (Watch the edge: if `hybrid` appears, ask whether it is a fourth exclusive value or the product of an `engine` axis — let the domain, not reflex, decide.)
