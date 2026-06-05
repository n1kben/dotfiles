# Types

How each modelling construct is written in ML-family type syntax (Elm shown).

```elm
type alias Customer =              -- entity / "and" → a record of fields
    { id : CustomerId              -- a wrapped id, never a bare Int/String
    , email : Email
    , payment : Payment
    }

type Payment                       -- "or" → a sum; each case owns only its fields
    = Cash
    | Card CardNumber
    | Invoice { ref : InvoiceRef, terms : Days }

type Email = Email String                    -- opaque value: constructor private,
fromString : String -> Result Error Email    -- built only through this gate
```

- **Record** — an entity's attributes, or any fields that co-occur ("and").
- **Sum** — mutually exclusive cases ("or"); never one record with half its fields blank.
- **Opaque primitive** — a value behind a private constructor and a fallible gate.
- **Lifecycle** — a type per state, transitions as functions: `place : Draft -> Placed`.
- **`Maybe` / `List`** — optionality / cardinality.
