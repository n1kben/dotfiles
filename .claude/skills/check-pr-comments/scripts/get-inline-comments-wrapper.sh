#!/bin/bash
# Wrapper script that finds and executes get-inline-comments.sh
# Works from ~/.claude/skills/ or project .claude/skills/

set -e

# Try to find the actual script in common locations
SCRIPT_LOCATIONS=(
    "~/.claude/skills/check-pr-comments/scripts/get-inline-comments.sh"
    ".claude/skills/check-pr-comments/scripts/get-inline-comments.sh"
    "$(pwd)/.claude/skills/check-pr-comments/scripts/get-inline-comments.sh"
)

for location in "${SCRIPT_LOCATIONS[@]}"; do
    # Expand tilde
    expanded=$(eval echo "$location")
    if [ -f "$expanded" ]; then
        exec bash "$expanded"
        exit 0
    fi
done

# If we get here, script wasn't found
echo "Error: Could not find get-inline-comments.sh in any standard location" >&2
echo "Searched:" >&2
for location in "${SCRIPT_LOCATIONS[@]}"; do
    echo "  - $(eval echo "$location")" >&2
done
exit 1
