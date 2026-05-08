---
name: sync
description: Commit, rebase on latest master, and push. Use when the user wants to quickly sync their branch.
---

Run these steps. Stop immediately if any step fails.

- Commit any changes
- Fetch latest origin master/main
- Rebase origin master/main (If the rebase has conflicts, stop and show them to the user — do NOT resolve automatically)
- Force push with lease
