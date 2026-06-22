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
