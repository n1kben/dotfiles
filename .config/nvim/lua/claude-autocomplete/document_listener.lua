local api = require("claude-autocomplete.api")
local preview = require("claude-autocomplete.completion_preview")
local config = require("claude-autocomplete.config")

local M = {}
M.timer = nil
M.last_request_time = 0
M.reference_content = nil
M.reference_file = nil

local function read_file(filepath)
  if not filepath then
    return nil
  end
  
  local file = io.open(filepath, "r")
  if not file then
    return nil
  end
  
  local content = file:read("*a")
  file:close()
  return content
end

local function get_current_content_with_cursor()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]
  
  if row <= #lines then
    local line = lines[row]
    lines[row] = line:sub(1, col) .. "^" .. line:sub(col + 1)
  end
  
  return table.concat(lines, "\n")
end

local function should_trigger_completion()
  local mode = vim.api.nvim_get_mode().mode
  if mode ~= "i" and mode ~= "ic" then
    return false
  end
  
  local ft = vim.bo.filetype
  if ft ~= "typescript" and ft ~= "typescriptreact" and ft ~= "tsx" then
    return false
  end
  
  local ignore_filetypes = config.config.ignore_filetypes or {}
  for _, ignored_ft in ipairs(ignore_filetypes) do
    if ft == ignored_ft then
      return false
    end
  end
  
  return true
end

local function trigger_completion()
  if not should_trigger_completion() then
    return
  end
  
  if not M.reference_content then
    return
  end
  
  local current_content = get_current_content_with_cursor()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  
  M.last_request_time = vim.loop.now()
  
  api.get_completion(M.reference_content, current_content, cursor_pos, function(suggestion)
    if suggestion and suggestion ~= "" then
      local cleaned_suggestion = suggestion:gsub("^%^", "")
      preview.show_suggestion(cleaned_suggestion)
    end
  end)
end

local function debounce_completion()
  if M.timer then
    vim.loop.timer_stop(M.timer)
  end
  
  M.timer = vim.loop.new_timer()
  M.timer:start(config.config.debounce_ms or 300, 0, vim.schedule_wrap(function()
    trigger_completion()
  end))
end

function M.on_text_changed()
  preview.clear_suggestion()
  debounce_completion()
end

function M.on_cursor_moved()
  preview.clear_suggestion()
end

function M.load_reference_file(filepath)
  if not filepath then
    return false
  end
  
  M.reference_content = read_file(filepath)
  if M.reference_content then
    M.reference_file = filepath
    return true
  end
  return false
end

function M.setup()
  local augroup = vim.api.nvim_create_augroup("ClaudeAutocomplete", {clear = true})
  
  vim.api.nvim_create_autocmd({"TextChangedI"}, {
    group = augroup,
    callback = M.on_text_changed,
  })
  
  vim.api.nvim_create_autocmd({"CursorMovedI"}, {
    group = augroup,
    callback = M.on_cursor_moved,
  })
  
  vim.api.nvim_create_autocmd({"InsertLeave"}, {
    group = augroup,
    callback = function()
      preview.clear_suggestion()
      if M.timer then
        vim.loop.timer_stop(M.timer)
      end
    end,
  })
end

return M