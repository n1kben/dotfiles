[[ -f "$HOME/.env" ]] && source "$HOME/.env"

export NODE_ENV="development"
export CLICOLOR=1
export EDITOR=nvim
export MANPAGER="nvim +Man!"
export GIT_MERGE_AUTOEDIT=no

# Self-locating: resolve this file's real path (through the stow symlink) and
# climb to the repo root, so DOTFILES is correct wherever the repo is cloned.
export DOTFILES="${${(%):-%x}:A:h:h:h}"
export VOLTA_HOME="$HOME/.volta"

export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$VOLTA_HOME/bin:$PATH"


eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# GitHub
# ----------------------------
# Per-folder account for the `gh` CLI: walk up from $PWD to the nearest
# ancestor containing a `.gh/` config dir and use it. If none is found, fail
# loudly rather than silently using the wrong account. An explicit
# GH_CONFIG_DIR in the environment is honored as-is (e.g. for first login).
# Tip: put a `.gh/` at $HOME if you want a catch-all default account.
#
# Defined here (not .zshrc) so non-interactive shells — e.g. tools that run
# `zsh -c '...'` without sourcing .zshrc — also pick the right account.
gh() {
  [[ -n $GH_CONFIG_DIR ]] && { command gh "$@"; return; }
  local dir=$PWD
  while [[ $dir != / ]]; do
    if [[ -f $dir/.gh/hosts.yml ]]; then
      GH_CONFIG_DIR=$dir/.gh command gh "$@"
      return
    fi
    dir=${dir:h}   # parent directory (zsh :h modifier)
  done
  print -u2 "gh: no .gh config dir found in $PWD or any parent directory"
  return 1
}
