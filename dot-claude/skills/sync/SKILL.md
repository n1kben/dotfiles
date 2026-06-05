---
name: sync
description: Commit, rebase onto latest master, and force-push the current branch. Trigger when the user wants to "sync", "sync my branch", "rebase and push", or bring their branch up to date with master.
---

Commit any outstanding changes, rebase onto the latest `origin/master` (or `origin/main`), then force-push with lease. Stop if any step fails — and if the rebase conflicts, show the user rather than resolving automatically.
