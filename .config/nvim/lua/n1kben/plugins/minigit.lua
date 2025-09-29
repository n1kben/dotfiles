return {
  'nvim-mini/mini-git',
  version = "false",
  lazy = false,
  config = function()
    require("mini.git").setup()
  end,
}
