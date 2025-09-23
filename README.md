# Dotfiles

Personal dotfiles managed with GNU Stow and Homebrew.

## Setup

1. Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Clone this repository to your home directory:

```bash
git clone <repository-url> ~/.files
cd ~/.files
```

3. Install the Homebrew packages defined in the Brewfile:

```bash
brew bundle --file ~/.files/Brewfile
```

4. Use stow to symlink the dotfiles:

```bash
stow .
```
