return {
  "williamboman/mason.nvim",
  lazy = false,
  opts = {
    ensure_installed = {
      "rescript-language-server",
      "lua-language-server",
      "typescript-language-server",
    },
  },
}
