-- lua/todo.lua
local M = {}

-- Default configuration
M.config = {
  local_filename = "TODO.md",    -- what to look for upwards in project
  global_filename = "~/TODO.md", -- global todo file
  keymap = {
    -- Below are the default binds, setting any value overrides it
    -- To inherit all defaults: set [1] = true
    normal = {
      -- true,  -- uncomment to inherit all defaults
      ["<leader>t"] = { function() M.open_todo_upwards() end, "Open local/project TODO" },
      ["<leader>T"] = { function() M.open_global_todo() end, "Open global TODO" },
    },
    insert = {
      -- true,  -- uncomment to inherit all defaults
      ["<C-t>"] = { function() M.insert_date() end, "Insert current date" },
    },
  },
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

-- Open global TODO
function M.open_global_todo()
  local global_todo = vim.fn.expand(M.config.global_filename)
  vim.cmd("edit " .. vim.fn.fnameescape(global_todo))
end

-- Insert current date
function M.insert_date()
  vim.api.nvim_put({ os.date("%Y-%m-%d") }, "c", true, true)
end

-- Internal: setup keymaps
local function apply_keymaps(keymaps)
  local modes = { ["normal"] = "n", ["insert"] = "i" }
  for mode, maps in pairs(keymaps) do
    for lhs, rhs in pairs(maps) do
      if type(rhs) == "table" then
        local fn, desc = rhs[1], rhs[2]
        if type(fn) == "function" then
          vim.keymap.set(modes[mode], lhs, fn, { desc = desc, noremap = true, silent = true })
        end
      end
    end
  end
end

-- Setup
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Commands
  vim.api.nvim_create_user_command("Todo", M.open_todo_upwards, {})
  vim.api.nvim_create_user_command("GlobalTodo", M.open_global_todo, {})

  -- Keymaps
  apply_keymaps(M.config.keymap)
end

return M
