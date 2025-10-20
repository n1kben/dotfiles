-- n1kben prelude - shared utilities for custom plugins
local M = {}

-- ============================================================================
-- BUFFER UTILITIES
-- ============================================================================

-- Create a read-only display buffer (for status displays, diffs, etc.)
function M.create_view_buffer(name, filetype)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(bufnr, 'swapfile', false)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)

  if filetype then
    vim.api.nvim_buf_set_option(bufnr, 'filetype', filetype)
  end

  if name then
    vim.api.nvim_buf_set_name(bufnr, name)
  end

  return bufnr
end

-- Create a unique buffer name with counter if needed
function M.create_unique_buffer_name(base_name)
  local name = base_name
  local counter = 1
  while vim.fn.bufexists(name) == 1 do
    name = base_name .. '-' .. counter
    counter = counter + 1
  end
  return name
end

-- ============================================================================
-- PATH UTILITIES
-- ============================================================================

-- Safely join path components
function M.join_path(...)
  local parts = { ... }
  if #parts == 0 then return "" end
  if #parts == 1 then return parts[1] end

  local result = parts[1]
  for i = 2, #parts do
    local part = parts[i]
    if part and part ~= "" then
      -- Remove leading slash from part, add trailing slash to result if needed
      part = part:gsub("^/+", "")
      if not result:match("/$") then
        result = result .. "/"
      end
      result = result .. part
    end
  end
  return result
end

-- Check if file exists and is readable
function M.file_exists(path)
  return vim.fn.filereadable(path) == 1
end

-- Escape path for vim commands
function M.escape_path(path)
  return vim.fn.fnameescape(path)
end



-- Walk up directory tree looking for a file
function M.find_file_upwards(filename, start_path)
  start_path = start_path or vim.fn.getcwd()
  local path = start_path
  local home = vim.fn.expand("~")
  local root = "/"

  while path and path ~= root and path ~= "" do
    local target = M.join_path(path, filename)
    if M.file_exists(target) then
      return target
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

  return nil
end

-- ============================================================================
-- TIME UTILITIES
-- ============================================================================

-- Format relative time (from fzf-undo.lua)
function M.format_relative_time(timestamp)
  if not timestamp or timestamp == 0 then return "original" end

  local diff = os.time() - timestamp
  if diff < 0 then return "future" end

  local units = {
    { 31556952, "year" },   -- seconds in a year
    { 2629746,  "month" },  -- seconds in a month
    { 604800,   "week" },   -- seconds in a week
    { 86400,    "day" },    -- seconds in a day
    { 3600,     "hour" },   -- seconds in an hour
    { 60,       "minute" }, -- seconds in a minute
    { 1,        "second" }  -- seconds
  }

  for _, unit in ipairs(units) do
    local seconds, name = unit[1], unit[2]
    local count = math.floor(diff / seconds)
    if count > 0 then
      return count == 1 and string.format("1 %s ago", name)
          or string.format("%d %ss ago", count, name)
    end
  end

  return "just now"
end

-- ============================================================================
-- GIT UTILITIES
-- ============================================================================

-- Get git repository root directory
function M.get_git_root()
  local root_output = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error == 0 then
    return root_output:gsub("%s+$", "") -- trim trailing whitespace
  end
  return nil
end


-- ============================================================================
-- WINDOW/UI UTILITIES
-- ============================================================================

-- Create a centered floating window
function M.create_centered_window(width, height, opts)
  opts = opts or {}

  -- Calculate dimensions if they're relative (0-1)
  if width <= 1 then width = math.floor(vim.o.columns * width) end
  if height <= 1 then height = math.floor(vim.o.lines * height) end

  -- Center the window
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local win_opts = vim.tbl_extend("force", {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  }, opts.win_opts or {})

  local bufnr = opts.bufnr or M.create_special_buffer(opts.buffer_opts)
  local winid = vim.api.nvim_open_win(bufnr, true, win_opts)

  return { winid = winid, bufnr = bufnr }
end

return M
