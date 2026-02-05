return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/ir-black-nvim",
    name = "ir-black",
    priority = 1000,
    enabled = false,
    config = function()
      require("ir-black-nvim").setup()
    end,
    init = function()
      vim.cmd.colorscheme("ir-black")
    end
  }
}
