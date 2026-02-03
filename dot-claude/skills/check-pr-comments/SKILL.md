---
name: check-pr-comments
description: Check the PR comments for the current branch to see if there's anything we need to address
allowed-tools: Bash(gh *), Bash(test *), Bash(bash ~/.claude/skills/check-pr-comments/scripts/get-inline-comments.sh), Bash(bash .claude/skills/check-pr-comments/scripts/get-inline-comments.sh)
---

Check the PR comments for the current branch and identify any action items or requests.

First, get the PR number and basic comments:
!`gh pr view --json number --jq '.number'`

PR comments: !`gh pr view --comments`

Now check for inline review comments (e.g., from Cursor Bugbot):
!`gh pr view --json reviews --jq '.reviews[] | .body'`

Get review comments with their status:
!`gh pr view --json reviews --jq '.reviews[] | {author: .author.login, state: .state, body: .body}'`

Check all comments including inline review comments:
!`gh pr view --json comments --jq '.comments[] | {author: .author.login, body: .body, createdAt: .createdAt}'`

Get detailed inline review comments with file paths and line numbers:
!`test -f ~/.claude/skills/check-pr-comments/scripts/get-inline-comments.sh && bash ~/.claude/skills/check-pr-comments/scripts/get-inline-comments.sh || bash .claude/skills/check-pr-comments/scripts/get-inline-comments.sh`

Analyze all the comments above and summarize:
1. Any requested changes or action items (including specific issues from inline review comments)
2. Questions that need answers
3. Approvals or positive feedback
4. Overall status of the PR
5. For automated review tools (like Cursor Bugbot), extract and clearly present the specific issues found
