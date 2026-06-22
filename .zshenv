# Bootstrap: zsh always reads ~/.zshenv first, before ZDOTDIR is known.
# Point it at the XDG config dir; every later rc file is read from there.
export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
