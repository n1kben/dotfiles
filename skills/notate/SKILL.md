---
name: notate
description: Lay a thing out as an indented monospace text structure — a tree, signature, schema, or flow — rather than prose. Trigger when the user wants something shown as structure rather than paragraphs — notate, outline, sketch, map it out, show the shape of it — but not when they want a rendered or graphical diagram, which is a drawing tool's job.
---

Re-represent the thing as an indented tree, not prose, so its shape reads at a glance — a directory or component tree for what nests, a call tree or UX flow for what runs top to bottom, branches for the states something moves between, type and interface signatures, a database or spreadsheet schema, or an API's endpoints for a contract, pseudocode for an algorithm. Annotate each node with what decides it — where it lives, what it owns, where it breaks — and where something's undecided leave a hole rather than fake it; the gap is usually the payload. Keep the marks light and vertical — indentation and arrows in a monospace block, one page, no boxes, frames, or columns — and to compare, group what agrees and flag what differs rather than tabulating. When there's no hidden shape and the value is in voice or nuance, leave it as prose.

Examples — mirror their density and annotation, no more.

Component tree — what nests (XML tags render, bare hooks hook in):

```ts
<SessionsPageWrapper> (app — owns activeTab, sessions, drafts)
  useSessionsHotkeys (tab switch, cmd+n)
  <SessionsPage> (packages/ui — pure, props only)
    <Tabs>
    <CreateSessionButton> (onClick → onCreate)
    <SessionTable> (owns editingId)
      useTableHotkeys (j/k nav, x select, enter open)
      <TableRow> (one per session)
```

Call tree — what runs top to bottom, → calls into, ↳ the branch that exits:

```ts
POST /links (routes/links.ts)
  → LinkCatalog.create (core)
    → Store.insert (sql.ts)
    → Index.add
  ↳ SlugTaken → 409 to client
```

UX flow — screens in sequence, → leads to the next, (parens) what happens there, ↳ a branch off it, ?? a hole where it's undecided:

```ts
Checkout (guest)
  → Cart (review items)
  → Shipping (enter address)
    ↳ invalid → stay, inline error
  → Payment (card details)
    ↳ declined → ?? retry vs bail to Cart — undecided
  → Confirm (place order)
  → Receipt
```

State branches — the route a record takes, event → target, indent tracks progress, ↺ loops back:

```
Draft
  submit → Pending
    approve → Active
      retire → Retired (terminal — no path back)
    reject → Rejected
      revise → ↺ Draft
```

Function interface — (positional)/{named} args, ? optional, ! effectful:

```js
LinkCatalog
  resolve(Slug) -> Result Link NotFound
  rename(Slug, Url) -> Link
  create({ slug: Slug, target?: Url }) -> Link
  save!(Link) -> {}
```

Algebraic types — {record} with ? optional, | union mixing tagged variants and bare types, Result, List:

```ts
Link =
  { slug: Slug
  , target: Url
  , label?: Str
  }
Event =
  | Created Link
  | Retired Slug
  | Num
Lookup = Result Link NotFound
Feed = List Link
```

Tabular schema — fields and relations of a database, spreadsheet, or record set:

```sql
users (table)
  id — uuid, primary key
  email — text, unique

links (table)
  slug — text, primary key
  owner_id — uuid → users.id (cascade)
  retired_at — timestamptz, null means live
```

API endpoints — a contract, METHOD path (body?) -> status Result, | alternative outcomes:

```ts
links API (REST, JSON, bearer auth)
  POST /links ({ slug?, target }) -> 201 Link | 409 SlugTaken
  GET /links/:slug -> 200 Link | 404
  PATCH /links/:slug ({ target }) -> 200 Link
  DELETE /links/:slug -> 204
```

Pseudocode — an algorithm, ← binds a name, → yields the result, : opens a block:

```ts
resolve(slug):
  row ← store.lookup(slug)
  if none → NotFound
  if row.retired → NotFound
  index.bump(slug)
  return row.link
```
