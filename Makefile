# Dotfiles installer — location-independent.
# Computes its own path, so `make install` works no matter where the repo is
# cloned (~/.files, ~/Developer/n1kben/dotfiles, anywhere).

DIR    := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
PARENT := $(patsubst %/,%,$(dir $(DIR)))
PKG    := $(notdir $(DIR))
STOW   := stow --dotfiles --target=$(HOME) --dir=$(PARENT)

.PHONY: install unstow brew help

PI_AGENT := $(HOME)/.pi/agent
PI_SYNC_PATHS := extensions keybindings.json prompts settings.json themes

help: ## Show available targets
	@grep -E '^[a-z][a-zA-Z-]*:.*##' $(MAKEFILE_LIST) | sed -E 's/:.*## /\t/'

install: ## Symlink dotfiles into $HOME, link Claude and Pi config, refresh @dotfiles mark
	@mkdir -p $(PI_AGENT)
	@for path in $(PI_SYNC_PATHS); do rm -rf "$(PI_AGENT)/$$path"; done
	$(STOW) --restow $(PKG)
	@mkdir -p $(HOME)/.claude
	ln -sfn "$(DIR)/claude/CLAUDE.md" "$(HOME)/.claude/CLAUDE.md"
	@mkdir -p $(HOME)/.marks
	ln -sfn "$(DIR)" "$(HOME)/.marks/@dotfiles"

unstow: ## Remove every symlink this repo created
	$(STOW) --delete $(PKG)
	rm -f "$(HOME)/.claude/CLAUDE.md"

brew: ## Install Homebrew packages from the Brewfile
	brew bundle --file="$(DIR)/Brewfile"
