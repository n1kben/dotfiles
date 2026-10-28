# Dotfiles installer — location-independent.
# Computes its own path, so `make install` works no matter where the repo is
# cloned (~/.files, ~/Developer/n1kben/dotfiles, anywhere).

DIR    := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
PARENT := $(patsubst %/,%,$(dir $(DIR)))
PKG    := $(notdir $(DIR))
STOW   := stow --dotfiles --target=$(HOME) --dir=$(PARENT)

.PHONY: install unstow brew help

help: ## Show available targets
	@grep -E '^[a-z][a-zA-Z-]*:.*##' $(MAKEFILE_LIST) | sed -E 's/:.*## /\t/'

install: ## Symlink dotfiles into $HOME and refresh the @dotfiles mark
	$(STOW) --restow $(PKG)
	@mkdir -p $(HOME)/.marks
	ln -sfn "$(DIR)" "$(HOME)/.marks/@dotfiles"

unstow: ## Remove every symlink this repo created
	$(STOW) --delete $(PKG)

brew: ## Install Homebrew packages from the Brewfile
	brew bundle --file="$(DIR)/Brewfile"
