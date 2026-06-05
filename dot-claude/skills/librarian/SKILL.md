---
name: librarian
description: Cache a remote git repository as a reusable local checkout so repeated reads reuse it instead of re-cloning. Trigger whenever a remote repo comes up as reference — the user pastes a GitHub/GitLab/Bitbucket URL, a `git@…` address, or `owner/repo` shorthand, or asks you to "look at", "check out", "clone", or "use as reference" a repo you don't have locally.
---

Keep one reusable local checkout per remote repository instead of re-cloning, so later references reuse a stable, up-to-date, partial-clone copy.

Run `bash checkout.sh <repo> --path-only` to resolve the local path, then read and search there. The `<repo>` can be a full URL, a `git@…` address, or `owner/repo` shorthand (defaulting to `github.com`). Call the script again on later references to refresh — fetches are throttled to every 5 minutes, or pass `--force-update` to force one now. It handles parsing, cloning, and fast-forwarding; read `checkout.sh` for the details.

Don't edit inside the shared cache; copy it or make a worktree for task-specific changes.
