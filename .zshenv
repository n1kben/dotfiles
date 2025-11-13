source "$HOME/.env"
export EDITOR=nvim
export MANPAGER="nvim +Man!"
export VOLTA_HOME="$HOME/.volta"
export DOTFILES="$HOME/.files"
export PATH="$VOLTA_HOME/bin:$PATH"
export PATH="$HOME/.bin:$PATH"
eval "$(/opt/homebrew/bin/brew shellenv)"
