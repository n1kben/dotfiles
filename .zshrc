# Zsh autosuggestions
# source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Zsh autocomplete
# source $(brew --prefix)/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# Git
export GIT_MERGE_AUTOEDIT=no
alias gf="fzg files"
alias gb="fzg branch"
alias gh="fzg history"
alias gsl="fzg stash"

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
export FZF_DEFAULT_OPTS="--color 16 --reverse"

# BAT
export BAT_THEME="base16"

# System
# ----------------------------
export CLICOLOR=1
alias -- -='cd -'
alias ..="cd ../"
alias ...="cd ../../"
alias ....="cd ../../../"
alias l="ls -l"
alias ll="ls -l"
alias la="ls -la"
alias c="clear"
alias r="source ~/.zshenv; source ~/.zprofile; source ~/.zshrc"

# Vim
alias v="vimmer"
vimmer() {
  if [ -z "$1" ]
    then
      nvim .
      return
  fi
  if [ -z "$2" ]
    then
      nvim $1
      return
  fi
  nvim +$2 $1
  return
}

# Node
export NODE_ENV="development"

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
