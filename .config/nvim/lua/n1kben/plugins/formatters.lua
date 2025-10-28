return {
  "formatters",
  dir = vim.fn.stdpath("config") .. "/lua/formatters",
  lazy = false,
  config = function()
    require("formatters").setup({
      auto_format = true,
      notify_on_error = true,
      fallback_to_lsp = true,
    })
  end,
}