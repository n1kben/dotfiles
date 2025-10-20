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

git() {
  local cmd="$1"
  local fzf_eligible_commands=("add" "rm" "checkout" "diff")

  # Commands that don't use fzf - run git normally
  if [[ ! " ${fzf_eligible_commands[*]} " =~ " $cmd " ]]; then
    command git "$@"
    return
  fi

  # Check if we should skip fzf (files already specified or "all files" flags)
  local arg
  for arg in "${@:2}"; do
    case "$arg" in
      --all|-A|-|.|*\**) # "All files" patterns
        command git "$@"
        return
        ;;
      -*) # Skip flags
        continue
        ;;
      *) # Found a file argument
        command git "$@"
        return
        ;;
    esac
  done

  # No files specified - use fzf for file selection
  local selected_files
  selected_files=$(fzg files)
  [[ -z "$selected_files" ]] && return 1  # User cancelled
  command git "$@" $selected_files
}

alias gf="fzg files"
alias gb="fzg branch"
alias gl="fzg history"
alias gsl="fzg stash"

alias g="git status"
alias gs="git status"
alias ga="git add"
alias gap="git add --all --intent-to-add && git add --patch"
alias gd="git diff"
alias gc="git commit -v --no-verify"
alias gco="git checkout"
alias gca="git add --all && git commit -v --no-verify"
alias gcaa="git add --all && git commit -v --no-verify --amend"
alias grm="git rm"
alias gp="git push origin \$(git rev-parse --abbrev-ref HEAD)"
alias gpf="git push origin \$(git rev-parse --abbrev-ref HEAD) --force-with-lease"
alias gpr="git pull --rebase origin \$(git rev-parse --abbrev-ref HEAD)"
alias gcb="git checkout \$(gb)"
alias gcf="git checkout \$(gf)"
alias gst="git stash --include-untracked"
alias ge="$EDITOR \$(gf)"
alias gk="git rebase --continue || git merge --continue"


# FZF
# ----------------------------
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--color 16 --reverse"


# BAT
# ----------------------------
export BAT_THEME="base16"
alias cat="bat -p --pager=never"



# System
# ----------------------------
export CLICOLOR=1

# cd
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

alias -- -='cd -'
alias ..="cd ../"
alias ...="cd ../../"
alias ....="cd ../../../"

# ls
alias l="ls -l"
alias ll="ls -l"
alias la="ls -la"

# mkdir
alias mkdir="mkdir -p"
mkcd() { mkdir -p "$1" && cd "$1" }

# rm
rm() {
  # If no arguments, use fzf to select files
  if [[ $# -eq 0 ]]; then
    local selected_files
    selected_files=$(fzg files)
    [[ -z "$selected_files" ]] && return 1  # User cancelled
    command rm $selected_files
  else
    command rm "$@"
  fi
}

# shortcuts
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


# Hook System
# ----------------------------
PRECMD_HOOKS=()

add_precmd_hook() {
  PRECMD_HOOKS+=("$1")
}

# Prompt
# ----------------------------
# Enable vcs_info for git branch display
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats ' (%b)'
zstyle ':vcs_info:*' enable git

# Set prompts
setopt PROMPT_SUBST
PROMPT='%F{blue}%1~%f%F{green}${vcs_info_msg_0_}%f λ '
RPROMPT='%F{black}%~%f'

_update_prompt() {
  vcs_info
}

add_precmd_hook "_update_prompt"


# Title
# ----------------------------
DISABLE_AUTO_TITLE="true"

_update_title() {
  # Skip if user has manually set title
  [[ -n "$MANUAL_TITLE" ]] && return
  
  local git_root git_branch
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  if [[ -n "$git_root" && -n "$git_branch" ]]; then
    # Show repo name and branch
    echo -ne "\e]1;${git_root##*/}:${git_branch}\a"
  else
    # Fallback: just show current dir name
    echo -ne "\e]1;${PWD##*/}\a"
  fi
}

title() {
  if [[ -z "$1" ]]; then
    # Clear manual title and reset to auto
    unset MANUAL_TITLE
    _update_title
  else
    # Set manual title
    export MANUAL_TITLE="$1"
    echo -ne "\e]1;$1\a"
  fi
}

add_precmd_hook "_update_title"


# Precmd Hook Runner
# ----------------------------
precmd() {
  for hook in "${PRECMD_HOOKS[@]}"; do
    $hook
  done
}


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
