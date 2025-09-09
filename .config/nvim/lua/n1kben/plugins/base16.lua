return {
  "RRethy/base16-nvim",
  lazy = false,
  init = function()
    vim.api.nvim_create_autocmd("OptionSet", {
      pattern = "background",
      callback = function()
        if vim.o.background == "dark" then
          vim.cmd.colorscheme("base16-irblack")
        else
          vim.cmd.colorscheme("base16-github")
        end
      end,
    })
  end,
}
