#!/bin/bash
# Get inline review comments for the current PR
# This script can be located anywhere under ~/.claude/

set -e

# Get PR number
PR_NUM=$(gh pr view --json number --jq '.number')

# Get inline comments using GitHub API
gh api "repos/{owner}/{repo}/pulls/$PR_NUM/comments" --jq '.[] | {path: .path, line: .line, body: .body, author: .user.login}'
