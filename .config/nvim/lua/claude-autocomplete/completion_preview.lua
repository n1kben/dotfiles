local M = {}

M.ns_id = vim.api.nvim_create_namespace("claude_autocomplete")
M.suggestion_group = "Comment"
M.current_suggestion = nil
M.extmark_id = nil

local function split_lines(text)
  local lines = {}
  for line in text:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

local function get_cursor_info()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local col = cursor[2]
  
  local line_before = line:sub(1, col)
  local line_after = line:sub(col + 1)
  
  return cursor, line, line_before, line_after
end

local function get_next_word(text)
  local word_end = text:match("^%S+")
  if word_end then
    return text:sub(1, #word_end)
  end
  return text
end

function M.show_suggestion(suggestion_text)
  M.clear_suggestion()
  
  if not suggestion_text or suggestion_text == "" then
    return
  end
  
  local mode = vim.api.nvim_get_mode().mode
  if mode ~= "i" and mode ~= "ic" then
    return
  end
  
  local cursor, line, line_before, line_after = get_cursor_info()
  local buf = vim.api.nvim_get_current_buf()
  
  local lines = split_lines(suggestion_text)
  local first_line = lines[1] or ""
  
  if #lines == 1 then
    local opts = {
      id = 1,
      virt_text = {{first_line, M.suggestion_group}},
      virt_text_win_col = vim.fn.virtcol(".") - 1,
      hl_mode = "combine",
    }
    M.extmark_id = vim.api.nvim_buf_set_extmark(buf, M.ns_id, cursor[1] - 1, cursor[2], opts)
  else
    local other_lines = {}
    for i = 2, #lines do
      table.insert(other_lines, {{lines[i], M.suggestion_group}})
    end
    
    local opts = {
      id = 1,
      virt_text = {{first_line, M.suggestion_group}},
      virt_lines = other_lines,
      virt_text_win_col = vim.fn.virtcol(".") - 1,
      hl_mode = "combine",
    }
    M.extmark_id = vim.api.nvim_buf_set_extmark(buf, M.ns_id, cursor[1] - 1, cursor[2], opts)
  end
  
  M.current_suggestion = {
    text = suggestion_text,
    cursor_pos = cursor,
    line_before = line_before,
    line_after = line_after,
  }
end

function M.clear_suggestion()
  if M.extmark_id then
    local buf = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_buf_del_extmark, buf, M.ns_id, 1)
    M.extmark_id = nil
  end
  M.current_suggestion = nil
end

function M.accept_suggestion()
  if not M.current_suggestion then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", true)
    return
  end
  
  local suggestion = M.current_suggestion
  M.clear_suggestion()
  
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Space><Left><Del>", true, false, true), "n", false)
  
  local cursor = vim.api.nvim_win_get_cursor(0)
  local range = {
    start = {
      line = cursor[1] - 1,
      character = cursor[2],
    },
    ["end"] = {
      line = cursor[1] - 1,
      character = vim.fn.col("$"),
    },
  }
  
  vim.lsp.util.apply_text_edits(
    {{range = range, newText = suggestion.text}},
    vim.api.nvim_get_current_buf(),
    "utf-8"
  )
  
  local lines = split_lines(suggestion.text)
  local last_line = lines[#lines]
  local new_cursor_pos = {cursor[1] + #lines - 1, cursor[2] + #last_line}
  vim.api.nvim_win_set_cursor(0, new_cursor_pos)
end

function M.accept_word()
  if not M.current_suggestion then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-Right>", true, false, true), "n", true)
    return
  end
  
  local suggestion = M.current_suggestion
  local word = get_next_word(suggestion.text)
  
  M.current_suggestion.text = word
  M.accept_suggestion()
end

function M.has_suggestion()
  return M.current_suggestion ~= nil
end

return M