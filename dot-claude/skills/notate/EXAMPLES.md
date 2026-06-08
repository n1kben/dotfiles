# Outline examples

Two worked specimens whose layout is non-obvious — mimic these when you reach for them. The other notations (types, state machines, invariants) render conventionally; no specimen needed.

## Call graph — production and test side by side

Align the two trees so the swap reads as a diff: the nodes that differ are exactly the boundary where fakes and in-memory implementations take over. Arrow-and-indent, one node per line.

Production:

```ts
HTTP handlers
  → LinkCatalog
    → LinkCatalog.layerDurableObject
      → Effect RPC over Durable Object fetch
        → LinkCatalog.layer
          → LinkCatalogCoordinator
            → LinkCatalogStore
              → LinkCatalogSqlExecutor
            → PublicRedirectIndexService
```

Tests:

```ts
HTTP handlers
  → LinkCatalog
    → linkCatalogMemoryLayer
      → LinkCatalog.layer
        → LinkCatalogCoordinator
          → LinkCatalogStore.layerMemory
          → PublicRedirectIndexService.layerMemory
```

The diff *is* the boundary: `layerDurableObject` + RPC transport collapse to `linkCatalogMemoryLayer`, and `LinkCatalogSqlExecutor` / `PublicRedirectIndexService` become their `.layerMemory` variants — while everything from `LinkCatalog.layer` down stays identical, proving the coordinator is exercised unchanged under test.

## Component tree — each node annotated with what it owns

A node per component, indented by nesting. Tag each with where it lives (`[package — role]`), then list the facts that decide it: state owned, hotkeys bound, callbacks provided, props received. The wrapper/pure boundary becomes legible — stateful wrappers own state and hotkeys; pure components only receive props.

```
apps/riptide-ui/storybook:
└─ <SessionsPageWrapper>                    [Storybook full demo]
     State:     activeTab, mockSessions, mockDrafts, mockArchived
     Hotkeys:   useSessionsPageHotkeys (tab switching, cmd+n create)
     Callbacks: handleCreateSession (mock), handleTabChange
   │
   └─ <SessionsPage>                        [packages/ui — pure page component]
        Props: sessions, drafts, archivedSessions, activeTab,
               onTabChange, onCreateSession, focusedSessionId,
               selectedSessionIds, ...table callbacks
      │
      ├─ <Tabs> + <TabsList> + <TabsTrigger>
      ├─ <CreateSessionButton onClick={onCreateSession}>
      │
      └─ <SessionTableWrapper>              [Storybook table demo]
           State:   focusedSessionId, selectedSessionIds
           Hotkeys: useSessionTableHotkeys
             - j/k: navigation
             - shift+j/k: range selection
             - x: toggle selection
             - meta+a: select/deselect all
             - enter: activate session
             - shift+r: start rename
             - e: archive/discard
             - alt+y: bypass permissions
           Callbacks: handleArchive, handleBulkArchive, handleDiscard,
                      handleBulkDiscard, handleActivateSession,
                      handleBypassPermissions
         │
         └─ <SessionTable>                  [packages/ui — pure table]
              Props: sessions, focusedSessionId, selectedSessionIds,
                     searchText, matchedSessions, isArchivedView,
                     isDraftsView, onRowClick, onToggleSelection,
                     onActivateSession, onSaveTitle, onArchive,
                     onDiscard, onBypassPermissions, onStartEdit
              Internal state: editingSessionId, editValue
            │
            ├─ <TableHeader>
            └─ <TableBody>
                 └─ <SessionTableRow>        [packages/ui — pure row]
```

Note the pattern the layout exposes: every `Wrapper` owns state + hotkeys and lives in the app; every node tagged `[packages/ui — pure …]` only takes props. State stops at the wrapper boundary.
