return {
  "FabijanZulj/blame.nvim",
  cmd = "BlameToggle",
  keys = {
    { "<leader>b", "<cmd>BlameToggle<cr>", { desc = "Blame: Toggle" } },
  },
  config = function()
    require("blame").setup({
      mappings = {
        commit_info = "i",
        stack_push = "<CR>",
        stack_pop = "-",
        show_commit = "o",
        close = { "q" },
      }
    })
  end,
}
