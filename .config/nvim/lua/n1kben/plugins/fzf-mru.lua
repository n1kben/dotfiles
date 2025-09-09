return {
  "vikfroberg/fzf-mru.nvim",
  dependencies = {
    "ibhagwan/fzf-lua"
  },
  lazy = false,
  opts = {},
  keys = {
    {
      "<leader>p",
      mode = "n",
      function()
        local source = require("mru").mru_files()
        require "fzf-lua".fzf_exec(source, {
          actions = {
            ["default"] = require "fzf-lua".actions.file_edit,
          },
        })
      end,
      { desc = "MRU Files" }
    },
  }
}
