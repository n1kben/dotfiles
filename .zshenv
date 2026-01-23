source "$HOME/.env"

export NODE_ENV="development"
export CLICOLOR=1
export EDITOR=nvim
export MANPAGER="nvim +Man!"
export GIT_MERGE_AUTOEDIT=no

export DOTFILES="$HOME/.files"
export VOLTA_HOME="$HOME/.volta"

export PATH="$HOME/.bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$VOLTA_HOME/bin:$PATH"


eval "$(/opt/homebrew/bin/brew shellenv)"
