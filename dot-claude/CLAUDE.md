When creating a branch always use checkout -b <branch_name> origin/main/master and be sure to fetch latest before

When referencing main/master in any git command (diff, log, rev-list, merge-base, etc.), use `origin/master` / `origin/main`, not the local ref — local is often stale. For diffs against the merge-base, use the three-dot form: `git diff origin/master...HEAD`. This diffs against the commit where the branch was cut, so files that landed on master after branching don't appear as spurious deletions.

Node is v22 (via Volta) and runs TypeScript natively — `node script.ts` just works, no ts-node, tsx, or compile step needed. Use this for one-off scripts and tools: write a single `.ts` file and run it directly. ESM syntax (`import` / top-level `await`) is fine. Type-only constructs are stripped at runtime; runtime values still need real imports.
