return {
  "williamboman/mason.nvim",
  cmd = "Mason",
  opts = {
    ensure_installed = {
      "rescript-language-server",
      "lua-language-server",
      "typescript-language-server",
    },
  },
}
