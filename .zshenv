source "$HOME/.env"

export EDITOR=nvim
export MANPAGER="nvim +Man!"

export PATH="$HOME/.bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

eval "$(/opt/homebrew/bin/brew shellenv)"
