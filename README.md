# Dotfiles

Personal dotfiles managed with GNU Stow and Homebrew.

## Setup

1. Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Clone this repository (location-independent — anywhere works):

```bash
git clone <repository-url> ~/Developer/n1kben/dotfiles
cd ~/Developer/n1kben/dotfiles
```

3. Install the Homebrew packages defined in the Brewfile:

```bash
make brew
```

4. Symlink the dotfiles into `$HOME`:

```bash
make install
```

`make install` computes the repo's location at runtime, so stow always targets
`$HOME` regardless of where this repo was cloned. Run `make help` for all
targets (`install`, `unstow`, `brew`).

## Claude config

Claude's global instructions live in `claude/CLAUDE.md`, and `make install`
symlinks them to `~/.claude/CLAUDE.md`.
