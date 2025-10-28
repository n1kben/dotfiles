# Claude Autocomplete for Neovim

A Neovim plugin that provides AI-powered autocomplete using Claude API, designed for migrating ReScript code to TypeScript.

## Features

- Real-time code suggestions using Claude Haiku
- Tab/Shift-Tab to accept full/partial suggestions
- Automatic reference file detection when opening .res files
- Inline preview similar to Supermaven

## Setup

1. Set your Anthropic API key:
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

2. Configure the plugin in your Neovim config:

```lua
require("claude-autocomplete").setup({
  keymaps = {
    accept_suggestion = "<Tab>",      -- Accept full suggestion
    accept_word = "<S-Tab>",          -- Accept next word only
    clear_suggestion = "<C-]>",       -- Clear current suggestion
  },
  -- Provide example files for better migration quality
  example_rescript_file = "/path/to/example.res",
  example_typescript_file = "/path/to/example.ts",
  debounce_ms = 300,
})
```

## Usage

1. Open a `.res` file - it will automatically be loaded as the reference
2. Open or create a `.ts`/`.tsx` file to start migrating
3. Start typing and suggestions will appear automatically
4. Press Tab to accept, Shift-Tab for word-by-word completion

## Commands

- `:ClaudeAutocompleteStatus` - Check plugin status
- `:ClaudeAutocompleteLoadReference <file>` - Manually load a reference file

## How it Works

The plugin watches for:
- `.res` files as reference files (source to migrate from)
- Active typing in TypeScript files
- Sends context to Claude API for migration suggestions
- Shows inline virtual text with suggestions