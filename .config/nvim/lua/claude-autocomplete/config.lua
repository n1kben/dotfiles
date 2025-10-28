local M = {}

M.default_config = {
  keymaps = {
    accept_suggestion = "<Tab>",
    accept_word = "<S-Tab>",
    clear_suggestion = "<C-]>",
  },
  example_rescript_file = nil,
  example_typescript_file = nil,
  ignore_filetypes = {"", "help", "markdown"},
  debounce_ms = 1000,
  disable_keymaps = false,
}

M.config = vim.deepcopy(M.default_config)

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(M.default_config), opts or {})
end

return M