# Development Commands

## Snacks Debug Usage
Global debug functions available anywhere in Neovim:

- `dd(...)` - Pretty print objects with treesitter highlighting
- `bt()` - Show a pretty backtrace  
- `:= {something = 123}` - Enhanced vim.print output

**Examples:**
```lua
dd(vim.lsp.buf_get_clients())  -- Debug LSP clients
dd({foo = "bar", nested = {a = 1, b = 2}})  -- Debug any object
bt()  -- Show current call stack
```
- Always use vim.print when debugging.