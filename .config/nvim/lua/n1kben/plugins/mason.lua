return {
  "williamboman/mason.nvim",
  cmd = "Mason",
  opts = {
    ensure_installed = {
      "rescript-language-server",
      "prettier",
      "typescript-language-server",
    },
  },
}
