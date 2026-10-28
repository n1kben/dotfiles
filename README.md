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

## Agent configuration

Agent instructions and skills are not in this repo. They live in `n1kben/agents`,
which symlinks `AGENTS.global.md` to `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.

Pi configuration lives in `n1kben/pi`, which links its extensions, themes,
keybindings, and settings into `~/.pi/agent`.
