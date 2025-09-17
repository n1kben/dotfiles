local function open_todo_upwards()
  local path = vim.fn.getcwd()

  local home = vim.fn.expand('~')
  local root = '/'

  while path and path ~= root and path ~= '' do
    local todo = path .. '/TODO.md'
    if vim.fn.filereadable(todo) == 1 then
      vim.cmd('edit ' .. vim.fn.fnameescape(todo))
      return
    end

    if path == home then
      break
    end

    local parent = vim.fn.fnamemodify(path, ":h")
    if parent == path then break end
    path = parent
  end

  vim.cmd('enew')
end
vim.api.nvim_create_user_command('Todo', open_todo_upwards, {})
vim.keymap.set('n', '<leader>t', ':Todo<CR>', { desc = 'Open TODO file' })

-- Function to open global TODO
local function open_global_todo()
  local global_todo = vim.fn.expand('~/.TODO.md')
  vim.cmd('edit ' .. global_todo)
end
vim.api.nvim_create_user_command('GlobalTodo', open_global_todo, {})
vim.keymap.set('n', '<leader>T', ':GlobalTodo<CR>', { desc = 'Open global TODO file' })

-- Date and time
vim.api.nvim_set_keymap('i', '<C-t>', '<C-o>:lua vim.api.nvim_put({os.date("%Y-%m-%d")}, "c", true, true)<CR>',
  { noremap = true, silent = true })
