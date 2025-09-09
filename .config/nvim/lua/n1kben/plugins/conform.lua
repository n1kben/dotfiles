return {
  "stevearc/conform.nvim",
  dependencies = {
    "williamboman/mason.nvim",
    "zapling/mason-conform.nvim",
  },
  init = function()
    require("mason").setup({})
    require("mason-conform").setup({})
    require("conform").setup({
      formatters_by_ft = {
        markdown = { "prettier" },
        html = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    })
  end,
}
