return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = true,
  opts = {
    background = { -- :h background
      light = "latte",
      dark = "mocha",
    },
  },
  init = function()
    vim.cmd.colorscheme("catppuccin")
  end
}
