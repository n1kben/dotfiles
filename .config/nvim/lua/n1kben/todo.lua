-- lua/todo.lua
local M = {}

-- Default configuration
M.config = {
  local_filename = "TODO.md",    -- what to look for upwards in project
}

-- Utility: safely join paths
local function join_path(...)
  return table.concat({ ... }, "/")
end

-- Open nearest TODO upwards
function M.open_todo_upwards()
  local path = vim.fn.getcwd()
  local home = vim.fn.expand("~")
  local root = "/"

  while path and path ~= root and path ~= "" do
    local todo = join_path(path, M.config.local_filename)
    if vim.fn.filereadable(todo) == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(todo))
      return
    end

    if path == home then
      break
    end

    local parent = vim.fn.fnamemodify(path, ":h")
    if parent == path then
      break
    end
    path = parent
  end

  vim.cmd("enew")
end

-- Insert current date
function M.insert_date()
  vim.api.nvim_put({ os.date("%Y-%m-%d") }, "c", true, true)
end

-- Setup
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Commands
  vim.api.nvim_create_user_command("Todo", M.open_todo_upwards, {})

  -- Keymaps
  vim.keymap.set("n", "<leader>t", M.open_todo_upwards,
    { desc = "Open local/project TODO", noremap = true, silent = true })
  vim.keymap.set("i", "<C-t>", M.insert_date, { desc = "Insert current date", noremap = true, silent = true })
end

return M
