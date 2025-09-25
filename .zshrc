# Brew
# ----------------------------
brew() {
  # Run brew normally
  command brew "$@"

  # If it's an install command, dump Brewfile after
  if [[ "$1" == "install" || "$1" == "uninstall" || "$1" == "upgrade" ]]; then
    command brew bundle dump --force --file="$DOTFILES/Brewfile"
  fi
}


# Git
# ----------------------------
export GIT_MERGE_AUTOEDIT=no

alias gf="fzg files"
alias gb="fzg branch"
alias gh="fzg history"
alias gsl="fzg stash"

alias g="git status"
alias gs="git status"
alias gaf="git add \$(gf)"
alias gap="git add --all --intent-to-add && git add --patch"
alias gd="git diff"
alias gc="git commit -v --no-verify"
alias gca="git add --all && git commit -v --no-verify"
alias gcaa="git add --all && git commit -v --no-verify --amend"
alias gl="gh"
alias gp="git push origin \$(git rev-parse --abbrev-ref HEAD)"
alias gpf="git push origin \$(git rev-parse --abbrev-ref HEAD) --force-with-lease"
alias gpr="git pull --rebase origin \$(git rev-parse --abbrev-ref HEAD)"
alias gcb="git checkout \$(gb)"
alias gcf="git checkout \$(gf)"
alias gst="git stash --include-untracked"
alias grmf="git rm \$(gf)"
alias rmf="rm \$(gf)"
alias grm="git checkout master && gpr && git checkout - && git rebase master"
alias gmm="git checkout master && gpr && git checkout - && git merge master"


# FZF
# ----------------------------
export FZF_DEFAULT_OPTS="--color 16 --reverse"


# BAT
# ----------------------------
export BAT_THEME="base16"
alias cat="bat -p --pager=never"



# System
# ----------------------------
export CLICOLOR=1

# cd
alias -- -='cd -'
alias ..="cd ../"
alias ...="cd ../../"
alias ....="cd ../../../"
cdl() { cd "$1" && ls }

# ls
alias l="ls -l"
alias ll="ls -l"
alias la="ls -la"

# mkdir
alias mkdir="mkdir -p"
mkcd() { mkdir -p "$1" && cd "$1" }

# shortcuts
alias c="clear"
alias r="source ~/.zshenv && source ~/.zprofile && source ~/.zshrc"


# History
# ----------------------------
# Number of commands to store in memory
export HISTSIZE=10000
# Number of commands to store in disk
export SAVEHIST=10000
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


# Node
# ----------------------------
export NODE_ENV="development"


# Fuzzy cd
# ----------------------------
fzcd() {
  local dir
  dir=$(fd -t d -H . | fzf ) || return
  BUFFER="cd $dir"
  CURSOR=$#BUFFER
  zle accept-line
}
zle -N fzcd
bindkey '^P' fzcd


# Command
# ----------------------------
alias k="fzc edit"
alias ka="fzc add"
fzcmd() { 
  local cmd="$(fzc)"
  # Put the command in the buffer
  BUFFER="$cmd"
  # Move cursor to end of line
  CURSOR=$#BUFFER
  # Accept and execute - this must be the LAST zle command
  zle accept-line
}
zle -N fzcmd
bindkey '^K' fzcmd


# Prompt
# ----------------------------
# Enable vcs_info
autoload -Uz vcs_info
precmd() { vcs_info }

# Configure vcs_info
zstyle ':vcs_info:git:*' formats ' (%b)'
zstyle ':vcs_info:*' enable git

# Set prompts
setopt PROMPT_SUBST
PROMPT='%F{blue}%1~%f%F{green}${vcs_info_msg_0_}%f λ '
RPROMPT='%F{black}%~%f'


# Syntax highlighting (must the last line)
# ----------------------------
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# Autosuggestions
# ----------------------------
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^I' complete-word # Tab for next word
bindkey '^[[Z' autosuggest-accept # Shift+Tab for full suggestion

autoload -Uz compinit
compinit
