# The MIT License (MIT)
#
# Copyright (c) 2024 Viktor (inspired by fzf-git.sh by Junegunn Choi)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# shellcheck disable=SC2039
  [[ $0 == - ]] && return

__fzf_brew_color() {
  if [[ -n $NO_COLOR ]]; then
    echo never
  else
    echo "${FZF_BREW_COLOR:-always}"
  fi
}

__fzf_brew_pager() {
  local pager
  pager="${FZF_BREW_PAGER:-less -R}"
  echo "${pager}"
}

if [[ $- =~ i ]]; then # ----------------------------------

if [[ $__fzf_brew_fzf ]]; then
  eval "$__fzf_brew_fzf"
else
  # Redefine this function to change the options
  _fzf_brew_fzf() {
    fzf --height 50% --tmux 90%,70% \
      --layout reverse --multi --min-height 20+ --border \
      --no-separator --header-border horizontal \
      --border-label-pos 2 \
      --color 'label:blue' \
      --preview-window 'right,50%' --preview-border line \
      --bind 'ctrl-/:change-preview-window(down,50%|hidden|)' "$@"
  }
fi

_fzf_brew_check() {
  if ! command -v brew > /dev/null 2>&1; then
    [[ -n $TMUX ]] && tmux display-message "Homebrew not installed"
    return 1
  fi
  return 0
}

_fzf_brew_formulae() {
  _fzf_brew_check || return

  brew leaves | xargs brew list --versions | \
    _fzf_brew_fzf -m --ansi \
      --border-label '🍺 Formulae (Leaves) ' \
      --header 'ALT-U (uninstall) ╱ ALT-A (all installed) ╱ CTRL-/ (preview)' \
      --preview-window 'hidden' \
      --bind 'alt-u:reload(brew uninstall {1} >/dev/null 2>&1; brew leaves | xargs brew list --versions)' \
      --bind 'alt-a:reload(brew list --formula --versions)' \
      --preview 'brew info {1} 2>/dev/null' "$@" | \
    awk '{print $1}'
}

_fzf_brew_casks() {
  _fzf_brew_check || return

  brew list --cask --versions | \
    _fzf_brew_fzf -m --ansi \
      --border-label '🍾 Installed Casks ' \
      --header 'ALT-U (uninstall) ╱ CTRL-/ (preview)' \
      --preview-window 'hidden' \
      --bind 'alt-u:reload(brew uninstall --cask {1} >/dev/null 2>&1; brew list --cask --versions)' \
      --preview 'brew info --cask {1} 2>/dev/null' "$@" | \
    awk '{print $1}'
}

_fzf_brew_all_formulae() {
  _fzf_brew_check || return

  # Start with empty list, search dynamically based on query
  _fzf_brew_fzf -m --ansi --disabled \
    --border-label '🔍 Search All Formulae ' \
    --header 'Type to search formulae ╱ CTRL-/ (preview)' \
    --preview-window 'hidden' \
    --bind "change:reload:sleep 0.1; brew search {q} 2>/dev/null | grep -v '==>' || true" \
    --preview 'brew info {1} 2>/dev/null' "$@" | \
    awk '{print $1}'
}

_fzf_brew_all_casks() {
  _fzf_brew_check || return

  # Start with empty list, search dynamically based on query
  _fzf_brew_fzf -m --ansi --disabled \
    --border-label '🔍 Search All Casks ' \
    --header 'Type to search casks ╱ CTRL-/ (preview)' \
    --preview-window 'hidden' \
    --bind "change:reload:sleep 0.1; brew search --cask {q} 2>/dev/null | grep -v '==>' || true" \
    --preview 'brew info --cask {1} 2>/dev/null' "$@" | \
    awk '{print $1}'
}

_fzf_brew_services() {
  _fzf_brew_check || return

  brew services list | tail -n +2 | \
    _fzf_brew_fzf -m --ansi \
      --border-label '⚙️  Brew Services ' \
      --header 'ALT-S (toggle start/stop) ╱ ALT-R (restart) ╱ ALT-U (uninstall) ╱ CTRL-/ (preview)' \
      --preview-window 'hidden' \
      --bind 'alt-s:reload(status=$(echo {} | awk "{print \$2}"); if [[ "$status" == "started" ]]; then brew services stop {1} >/dev/null 2>&1; else brew services start {1} >/dev/null 2>&1; fi; brew services list | tail -n +2)' \
      --bind 'alt-r:reload(brew services restart {1} >/dev/null 2>&1; brew services list | tail -n +2)' \
      --bind 'alt-u:reload(brew uninstall {1} >/dev/null 2>&1; brew services list | tail -n +2)' \
      --preview 'brew services info {1} 2>/dev/null' "$@" | \
    awk '{print $1}'
}

_fzf_brew_taps() {
  _fzf_brew_check || return

  brew tap | \
    _fzf_brew_fzf -m --ansi \
      --border-label '🚰 Taps ' \
      --header 'ALT-U (untap/remove) ╱ CTRL-/ (preview)' \
      --preview-window 'hidden' \
      --bind 'alt-u:reload(brew untap {1} >/dev/null 2>&1; brew tap)' \
      --preview 'brew tap-info {1} 2>/dev/null' "$@"
}

_fzf_brew_outdated() {
  _fzf_brew_check || return

  brew outdated --verbose | \
    _fzf_brew_fzf -m --ansi \
      --border-label '📦 Outdated Packages ' \
      --header 'ALT-U (uninstall) ╱ ALT-G (upgrade) ╱ CTRL-/ (preview)' \
      --preview-window 'hidden' \
      --bind 'alt-u:reload(brew uninstall {1} >/dev/null 2>&1; brew outdated --verbose)' \
      --bind 'alt-g:reload(brew upgrade {1} >/dev/null 2>&1; brew outdated --verbose)' \
      --preview 'brew info {1} 2>/dev/null' "$@" | \
    awk '{print $1}'
}

_fzf_brew_pinned() {
  _fzf_brew_check || return

  brew list --pinned --versions | \
    _fzf_brew_fzf -m --ansi \
      --border-label '📌 Pinned Formulae ' \
      --header 'ALT-U (uninstall) ╱ ALT-P (unpin) ╱ CTRL-/ (preview)' \
      --preview-window 'hidden' \
      --bind 'alt-u:reload(brew uninstall {1} >/dev/null 2>&1; brew list --pinned --versions)' \
      --bind 'alt-p:reload(brew unpin {1} >/dev/null 2>&1; brew list --pinned --versions)' \
      --preview 'brew info {1} 2>/dev/null' "$@" | \
    awk '{print $1}'
}

_fzf_brew_list_bindings() {
  cat <<'EOF'

CTRL-B ? to show this list
CTRL-B CTRL-F for installed Formulae (leaves)
CTRL-B CTRL-C for installed Casks
CTRL-B CTRL-A for All formulae (search)
CTRL-B CTRL-K for all casKs (search)
CTRL-B CTRL-S for Services
CTRL-B CTRL-T for Taps
CTRL-B CTRL-O for Outdated packages
CTRL-B CTRL-P for Pinned formulae

Inside fzf:
  ALT-U for Uninstall/remove
  ALT-G for Upgrade (outdated view)
  ALT-S for Start/stop toggle (services)
  ALT-R for Restart (services)
  CTRL-/ for Preview toggle
EOF
}

fi # --------------------------------------------------------------------------

if [[ $- =~ i ]]; then # ------------------------------------------------------
if [[ -n "${BASH_VERSION:-}" ]]; then
  __fzf_brew_init() {
    bind -m emacs-standard '"\er":  redraw-current-line'
    bind -m emacs-standard '"\C-z": vi-editing-mode'
    bind -m vi-command     '"\C-z": emacs-editing-mode'
    bind -m vi-insert      '"\C-z": emacs-editing-mode'

    local o c
    for o in "$@"; do
      c=${o:0:1}
      if [[ $c == '?' ]]; then
        bind -x "\"\\C-b$c\": _fzf_brew_list_bindings"
        continue
      fi
      bind -m emacs-standard '"\C-b\C-'$c'": " \C-u \C-a\C-k`_fzf_brew_'$o'`\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\er \C-h"'
      bind -m vi-command     '"\C-b\C-'$c'": "\C-z\C-b\C-'$c'\C-z"'
      bind -m vi-insert      '"\C-b\C-'$c'": "\C-z\C-b\C-'$c'\C-z"'
      bind -m emacs-standard '"\C-b'$c'":    " \C-u \C-a\C-k`_fzf_brew_'$o'`\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\er \C-h"'
      bind -m vi-command     '"\C-b'$c'":    "\C-z\C-b'$c'\C-z"'
      bind -m vi-insert      '"\C-b'$c'":    "\C-z\C-b'$c'\C-z"'
    done
  }
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  __fzf_brew_join() {
    local item
    while read -r item; do
      echo -n -E "${(q)${(Q)item}} "
    done
  }

  __fzf_brew_init() {
    setopt localoptions no_glob
    local m o
    for o in "$@"; do
      if [[ ${o[1]} == "?" ]];then
        eval "fzf-brew-$o-widget() { zle -M '$(_fzf_brew_list_bindings)' }"
      else
        eval "fzf-brew-$o-widget() { local result=\$(_fzf_brew_$o | __fzf_brew_join); zle reset-prompt; LBUFFER+=\$result }"
      fi
      eval "zle -N fzf-brew-$o-widget"
      for m in emacs vicmd viins; do
        eval "bindkey -M $m '^b^${o[1]}' fzf-brew-$o-widget"
        eval "bindkey -M $m '^b${o[1]}' fzf-brew-$o-widget"
      done
    done
  }
fi
__fzf_brew_init formulae casks all_formulae all_casks services taps outdated pinned '?list_bindings'

fi # --------------------------------------------------------------------------
