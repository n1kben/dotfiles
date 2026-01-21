return {
  "williamboman/mason.nvim",
  lazy = false,
  opts = {
    ensure_installed = {
      "marksman",
      "lua-language-server",
      "rescript-language-server",
      "prettier",
      "typescript-language-server",
      "bash-language-server",
      "shfmt",
    },
  },
}
