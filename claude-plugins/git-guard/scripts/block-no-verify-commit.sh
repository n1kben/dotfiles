#!/usr/bin/env bash
# git-guard: block `git commit --no-verify` (and the `-n` short flag) when
# issued through Claude Code's Bash tool, so the repo's pre-commit hooks
# (e.g. the identity-leak guard) can't be silently bypassed.
#
# Reads a PreToolUse hook payload on stdin. When the command is a `git commit`
# invocation that disables verification it prints a deny decision; otherwise it
# exits 0 (no opinion). Designed to avoid false positives on unrelated commands
# such as `git log -n 5` or a commit message that merely contains "-n".

set -uo pipefail
set -f # split the command line on whitespace without glob expansion

payload="$(cat)"

# Pull out the command. Bail quietly if jq is unavailable or the field is empty.
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null)" || exit 0
[ -n "$cmd" ] || exit 0

deny() {
  jq -n --arg r "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

# Normalize the command into a flat token stream we can walk:
#   1. drop quoted spans  — real flags never live inside quotes, and this
#      removes any "-n"/separator text hiding inside a commit message;
#   2. turn newlines into the `|` separator;
#   3. pad every shell separator (&& || ; |) so it tokenizes on its own.
clean="$(printf '%s' "$cmd" \
  | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g" \
  | tr '\n' '|' \
  | sed -E 's/(\&\&|\|\||;|\|)/ | /g')"

# shellcheck disable=SC2086
set -- $clean

blocked=0
while [ "$#" -gt 0 ]; do
  # Find the next `git` executable (handles env prefixes / absolute paths).
  case "$1" in
    git | */git) shift ;;
    *) shift; continue ;;
  esac

  # Skip git's global options to reach the subcommand.
  while [ "$#" -gt 0 ]; do
    case "$1" in
      "|") break ;; # separator before any subcommand
      -C | -c | --git-dir | --work-tree | --namespace | --exec-path | --super-prefix)
        shift; [ "$#" -gt 0 ] && shift; continue ;; # consumes a separate arg
      --*=* | -*) shift; continue ;;                # --flag=value, or other flag
      *) break ;;
    esac
  done

  # Not a commit? Keep scanning for the next `git`.
  [ "$#" -gt 0 ] && [ "$1" = "commit" ] || continue
  shift

  # Scan commit's own options until a separator or end of options.
  while [ "$#" -gt 0 ]; do
    case "$1" in
      "|" | "--") break ;;
      --no-verify) blocked=1; break ;;
      --*) shift; continue ;;                          # other long option
      -*) case "$1" in *n*) blocked=1; break ;; esac   # short cluster with n
          shift; continue ;;
      *) shift; continue ;;                            # positional (e.g. pathspec)
    esac
  done

  [ "$blocked" -eq 1 ] && break
done

if [ "$blocked" -eq 1 ]; then
  deny "Blocked by git-guard: 'git commit --no-verify' / '-n' is disabled so the pre-commit hooks (incl. the identity-leak guard) always run. If a commit is legitimately blocked, fix the flagged content instead of bypassing — or ask the user to commit manually."
fi

exit 0
