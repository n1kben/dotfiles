-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

_G.config = _G.config or {}
function config.visual_set_search(cmdtype)
  local tmp = vim.fn.getreg("s")
  vim.cmd.normal({ args = { 'gv"sy' }, bang = true })
  vim.fn.setreg("/", "\\V" .. vim.fn.escape(vim.fn.getreg("s"), cmdtype .. "\\"):gsub("\n", "\\n"))
  vim.fn.setreg("s", tmp)
end

-- Movement
vim.keymap.set({ "n", "o", "x" }, "B", "^", { desc = "Move to start of line" })
vim.keymap.set({ "n", "o", "x" }, "E", "$", { desc = "Move to end of line" })

vim.keymap.set({ "n", "x" }, "j", "gj", { desc = "Move down" })
vim.keymap.set({ "n", "x" }, "k", "gk", { desc = "Move up" })
vim.keymap.set({ "n", "x" }, "J", "5j", { desc = "Move down 5 lines" })
vim.keymap.set({ "n", "x" }, "K", "5k", { desc = "Move up 5 lines" })

vim.keymap.set({ "n", "x" }, "L", "5l", { desc = "Move right 5 lines" })
vim.keymap.set({ "n", "x" }, "H", "5h", { desc = "Move left 5 lines" })

-- Flip repeat and repeat reverse
vim.keymap.set("n", ",", ";", { desc = "Repeat last motion forwards" })
vim.keymap.set("n", ";", ",", { desc = "Repeat last motion backwards" })

-- Session
vim.keymap.set("n", "s", ":w<CR>", { desc = "Save file" })
vim.keymap.set("n", "S", ":wq<CR>", { desc = "Save and quit" })
vim.keymap.set("n", "q", ":bw<CR>", { desc = "Close buffer" })
vim.keymap.set("n", "Q", ":q<CR>", { desc = "Quit" })

-- Editing
vim.keymap.set("n", "u", "u", { desc = "Undo" })
vim.keymap.set("n", "<C-U>", "U", { desc = "Undo line" })
vim.keymap.set("n", "U", "<C-R>", { desc = "Redo" })

-- Sane operators
vim.keymap.set("x", "V", "$", { desc = "Select to end of line" })
vim.keymap.set("x", "v", "V", { desc = "Select line" })
vim.keymap.set("x", "y", "ygv<Esc>", { desc = "Yank visual selection" })
vim.keymap.set("n", "V", "v$h", { desc = "Select to end of line" })
vim.keymap.set("n", "Y", "y$", { desc = "Yank to end of line" })

-- Windows
-- vim.keymap.set("n", "<C-l>", "<C-W><C-L>", { desc = "Move to left window" })
-- vim.keymap.set("n", "<C-k>", "<C-W><C-K>", { desc = "Move to upper window" })
-- vim.keymap.set("n", "<C-j>", "<C-W><C-J>", { desc = "Move to lower window" })
-- vim.keymap.set("n", "<C-h>", "<C-W><C-H>", { desc = "Move to right window" })

-- Indentation
vim.keymap.set("n", "<Tab>", ">>", { desc = "Indent right" })
vim.keymap.set("n", "<S-Tab>", "<<", { desc = "Indent left" })
vim.keymap.set("x", "<Tab>", ">gv", { desc = "Indent right" })
vim.keymap.set("x", "<S-Tab>", "<gv", { desc = "Indent left" })

-- Search
vim.keymap.set("n", "<esc>", "<cmd>nohls<cr>", { desc = "Clear search highlight" })
vim.keymap.set("n", "<leader>n", "*", { desc = "Search word under cursor forwards" })
vim.keymap.set("n", "<leader>r", [[:%s/<C-r><C-w>//g<Left><Left>]], { desc = "Replace word under cursor" })
vim.keymap.set("x", "r", '"hy:%s/<C-r>h//gc<left><left><left>', { desc = "Replace visual selection" })
vim.keymap.set(
  "x",
  "n",
  ':lua config.visual_set_search("/")<CR>/<C-R>=@/<CR><CR>',
  { desc = "Search visual selection" }
)

-- Diagnostics
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })

-- LSP
vim.keymap.set("n", "gk", vim.lsp.buf.hover, { desc = "Hover" })
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })

-- Join lines
vim.keymap.set("n", "gj", "J", { desc = "Join lines" })

-- Regex popup
vim.keymap.set("n", "<leader>x", function()
  require("n1kben.regex-popup").show_regex_popup()
end, { desc = "Show regex popup with highlights" })

-- Git dashboard (replaces old git-status) - now uses plugin command
vim.keymap.set("n", "<leader>g", "<cmd>GitCast<cr>", { desc = "Open git dashboard" })

-- Reload config
vim.keymap.set("n", "R", function()
  dofile(vim.env.MYVIMRC)
end, { desc = "Reload neovim config" })
