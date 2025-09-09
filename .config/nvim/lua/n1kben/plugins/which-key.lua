return {
  "folke/which-key.nvim",
  lazy = false,
  opts = {
    plugins = {
      marks = false,
      registers = false,
      spelling = { enabled = false },
    },
    icons = {
      mappings = false,
    },
  },
  keys = {
    {
      "?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
