return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>T", "<cmd>TodoFzfLua<cr>", desc = "Todo comments" },
  },
  config = function()
    require("todo-comments").setup()
  end,
}
