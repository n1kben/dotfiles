return {
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  keys = {
    { "gj", function() require("treesj").join() end,  desc = "Join lines" },
    { "gk", function() require("treesj").split() end, desc = "Split lines" },
  },
  opts = {
    use_default_keymaps = false,
  },
}
