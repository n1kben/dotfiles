local config = require("claude-autocomplete.config")
local preview = require("claude-autocomplete.completion_preview")
local listener = require("claude-autocomplete.document_listener")

local M = {}

function M.setup(opts)
  config.setup(opts)
  
  if not config.config.disable_keymaps then
    if config.config.keymaps.accept_suggestion then
      vim.keymap.set("i", config.config.keymaps.accept_suggestion, preview.accept_suggestion, {
        noremap = true,
        silent = true,
        desc = "Accept Claude autocomplete suggestion"
      })
    end
    
    if config.config.keymaps.accept_word then
      vim.keymap.set("i", config.config.keymaps.accept_word, preview.accept_word, {
        noremap = true,
        silent = true,
        desc = "Accept Claude autocomplete word"
      })
    end
    
    if config.config.keymaps.clear_suggestion then
      vim.keymap.set("i", config.config.keymaps.clear_suggestion, preview.clear_suggestion, {
        noremap = true,
        silent = true,
        desc = "Clear Claude autocomplete suggestion"
      })
    end
  end
  
  listener.setup()
  
  vim.api.nvim_create_user_command("ClaudeAutocompleteStatus", function()
    local status = {}
    table.insert(status, "Claude Autocomplete Status:")
    table.insert(status, "  API Key: " .. (vim.env.ANTHROPIC_API_KEY and "Set" or "Not set"))
    table.insert(status, "  Reference file: " .. (listener.reference_file or "None loaded"))
    table.insert(status, "  Example files configured: " .. 
      ((config.config.example_rescript_file and config.config.example_typescript_file) and "Yes" or "No"))
    
    vim.notify(table.concat(status, "\n"), vim.log.levels.INFO)
  end, {})
  
  vim.api.nvim_create_user_command("ClaudeAutocompleteLoadReference", function(args)
    local filepath = args.args
    if not filepath or filepath == "" then
      filepath = vim.api.nvim_buf_get_name(0)
    end
    
    if filepath and filepath ~= "" then
      if listener.load_reference_file(filepath) then
        vim.notify("Loaded reference file: " .. vim.fn.fnamemodify(filepath, ":t"), vim.log.levels.INFO)
      else
        vim.notify("Failed to load file: " .. filepath, vim.log.levels.ERROR)
      end
    else
      vim.notify("No file to load", vim.log.levels.ERROR)
    end
  end, {
    nargs = "?",
    complete = "file",
    desc = "Load a reference file for Claude autocomplete (current file if no argument)"
  })
end

return M