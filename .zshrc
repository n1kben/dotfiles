# Brew
# ----------------------------
brew() {
  # Run brew normally
  command brew "$@"

  # If it's an install command, dump Brewfile after
  if [[ "$1" == "install" || "$1" == "uninstall" || "$1" == "upgrade" || "$1" == "tap" || "$1" == "untap" ]]; then
    command brew bundle dump --force --file="$DOTFILES/Brewfile"
  fi
}


# Git
# ----------------------------
alias gl="fzg history"
alias g="git status"
alias gs="git status"
alias gaa="git add --all"
alias gai="git add --intent-to-add"
alias gap="git add --patch"
alias gd="git diff"
alias gc="git commit -v"
alias gca="git add --all && git commit -v"
alias gp="git push origin \$(git rev-parse --abbrev-ref HEAD)"
alias gpf="git push origin \$(git rev-parse --abbrev-ref HEAD) --force-with-lease"
alias gpr="git pull --rebase origin \$(git rev-parse --abbrev-ref HEAD)"
alias gpm="git pull origin \$(git rev-parse --abbrev-ref HEAD)"
alias gcb="git checkout \$(fzg branch)"
alias b='git checkout $(basename "$PWD")'
alias grm="git fetch origin master && git rebase origin/master"
alias g-="git checkout -"
alias g.="git checkout ."
alias s='git add --all && git commit -m "Snapshot: $(date +"%Y-%m-%d %H:%M:%S")"'


# FZF
# ----------------------------
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--color 16 --reverse"

# alt+c to cd
# ctrl+t to paste file
# ctrl+r for history

source ~/.fzf-git.sh
# ctrl+g ?

source ~/.fzf-brew.sh
# ctrl+b ?


# BAT
# ----------------------------
export BAT_THEME="base16"
alias cat="bat -p --pager=never"



# cd
# ----------------------------

cd() {
  # If no arguments, use fzf to select directory
  if [[ $# -eq 0 ]]; then
    local selected_dir
    selected_dir=$(fd -t d -H . | fzf)
    [[ -z "$selected_dir" ]] && return 1  # User cancelled
    builtin cd "$selected_dir"
  else
    builtin cd "$@"
  fi
}

 alias .="cd -P ."
alias -- -='cd -'
alias ..="cd ../"
alias ...="cd ../../"
alias ....="cd ../../../"


# Marks
# ----------------------------

export CDPATH=.:~/.marks

mkdir -p ~/.marks

mark() {
  [ -z "$1" ] && { echo "usage: mark <name>"; return 1; }
  ln -sn "$(pwd)" ~/.marks/"$1"
}
marks() {
  local dest
  dest=$(ls ~/.marks | fzf) || return
  cd ~/.marks/"$dest"
}


# ls
# ----------------------------

alias l="ls -l"
alias ll="ls -l"
alias la="ls -la"


# mkdir
# ----------------------------

alias mkdir="mkdir -p"
mkcd() { mkdir -p "$1" && cd "$1" }


# Shortcuts
# ----------------------------

alias c="clear"
alias r="source ~/.zshenv && source ~/.zprofile && source ~/.zshrc"


# History
# ----------------------------
# Number of commands to store in memory
export HISTSIZE=10000000
# Number of commands to store in disk
export SAVEHIST=10000000
# Ignore duplicated commands during session
setopt HIST_IGNORE_ALL_DUPS
# Ignore duplicated commands when saving to hist file
setopt HIST_SAVE_NO_DUPS
# Append commands to history file instead of overwriting it
setopt append_history
# Append commands to history file as soon as they are run (instead of when the session ends)
setopt inc_append_history


# Vim
# ----------------------------
v() {
  if [ "$#" -eq 1 ]; then
    if [ -d "$1" ]; then
      (cd "$1" && nvim .)
    else
      nvim "$1"
    fi
  else
    nvim .
  fi
}


# Tmux
# ----------------------------

fztmux() {
  local selected_session
  selected_session=$(tmux list-sessions -F "#{session_name}" | fzf) || return
  tmux attach -d -t "$selected_session"
  zle accept-line
}
zle -N fztmux
bindkey '^P' fztmux


# Prompt
# ----------------------------

autoload -Uz vcs_info add-zsh-hook

zstyle ':vcs_info:git:*' formats ' (%b)'
zstyle ':vcs_info:*' enable git

setopt PROMPT_SUBST

PROMPT='%F{blue}%1~%f%F{green}${vcs_info_msg_0_}%f λ '
RPROMPT='%F{black}%~%f'

_update_prompt() {
  vcs_info
}

add-zsh-hook precmd _update_prompt


# Syntax highlighting (must the last line)
# ----------------------------
[[ -f $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# Autosuggestions
# ----------------------------
[[ -f $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^I' complete-word # Tab for next word
bindkey '^[[Z' autosuggest-accept # Shift+Tab for full suggestion

autoload -Uz compinit
compinit
