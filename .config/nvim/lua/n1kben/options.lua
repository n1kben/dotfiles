-- Swap files
vim.opt.swapfile = false

-- Auto change dir
vim.opt.autochdir = false

-- Win border
-- vim.opt.winborder = "rounded"

-- Undofile
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"

-- Scroll
vim.opt.scrolloff = 7

-- Line
vim.opt.number = false
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.list = true -- Hint characters

-- Cmdline
vim.opt.showmode = false

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Incsearch
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true

-- Tabs
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Keywords
vim.opt.iskeyword:append("-")

-- Yank highlight
local highlight_yank_group = vim.api.nvim_create_augroup("highlight_yank", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  group = highlight_yank_group,
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 500 })
  end,
})

-- Neovide
if vim.g.neovide then
  vim.o.guifont = "SauceCodePro Nerd Font Mono:h18"
  vim.g.neovide_padding_top = 30
  vim.g.neovide_padding_bottom = 30
  vim.g.neovide_padding_left = 30
  vim.g.neovide_padding_right = 30
  if vim.fn.argc() == 0 then
    local notes = vim.fn.expand("~/Dropbox/Notes")
    vim.cmd.cd(notes)
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        vim.schedule(function()
          require("oil").open(notes)
        end)
      end,
    })
  end
  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_cursor_trail_size = 0
  vim.g.neovide_cursor_animate_in_insert_mode = false
  vim.g.neovide_cursor_animate_command_line = false
end

-- o or O don’t automatically continue the comment from the previous line
local formatoptions_group = vim.api.nvim_create_augroup("formatoptions", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = formatoptions_group,
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove("o")
    vim.opt_local.formatoptions:remove("O")
  end,
})
