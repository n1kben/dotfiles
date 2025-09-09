# Dotfiles

Personal dotfiles managed with GNU Stow.

## Prerequisites

### Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install GNU Stow

```bash
brew install stow
```

## Setup

1. Clone this repository to your home directory:

```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
```

2. Use stow to symlink the dotfiles:

```bash
# Symlink all dotfiles at once
stow .
```

### Unstowing

To remove all symlinks created by stow:

```bash
cd ~/dotfiles
stow -D .
```

