local M = {}

local function get_word_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  
  local start_pos = col
  local end_pos = col
  
  while start_pos > 0 and line:sub(start_pos, start_pos):match("[%w%p]") do
    start_pos = start_pos - 1
  end
  start_pos = start_pos + 1
  
  while end_pos < #line and line:sub(end_pos + 1, end_pos + 1):match("[%w%p]") do
    end_pos = end_pos + 1
  end
  
  local regex = line:sub(start_pos, end_pos)
  
  -- Remove surrounding slashes if present (common regex notation)
  if regex:match("^/.*/$") then
    regex = regex:sub(2, -2)
  end
  
  return regex
end


local function highlight_matches(buf, regex)
  vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
  
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  
  local js_code = string.format([[
    try {
      const regexStr = %s;
      const regex = new RegExp(regexStr, 'g');
      const lines = %s;
      const matches = [];
      
      lines.forEach((line, lineIndex) => {
        let match;
        regex.lastIndex = 0;
        while ((match = regex.exec(line)) !== null) {
          matches.push({
            line: lineIndex,
            start: match.index,
            finish: match.index + match[0].length
          });
          if (!regex.global) break;
        }
      });
      
      console.log(JSON.stringify(matches));
    } catch (error) {
      console.log("[]");
    }
  ]], vim.json.encode(regex), vim.json.encode(lines))
  
  
  local result = vim.fn.system('node -e ' .. vim.fn.shellescape(js_code))
  
  -- Extract just the JSON part (everything after the last newline)
  local lines = vim.split(result, '\n')
  local json_result = lines[#lines] or ""
  if json_result == "" and #lines > 1 then
    json_result = lines[#lines - 1] or ""
  end
  
  
  if vim.v.shell_error == 0 then
    local cleaned_result = json_result:gsub('%s+$', '')
    
    if cleaned_result == "" then
      return
    end
    
    local ok, matches = pcall(vim.json.decode, cleaned_result)
    if ok and type(matches) == "table" then
      for _, match in ipairs(matches) do
        vim.api.nvim_buf_add_highlight(
          buf,
          -1,
          "Search",
          match.line,
          match.start,
          match.finish
        )
      end
    end
  end
end

function M.show_regex_popup()
  local regex = get_word_under_cursor()
  
  if regex == "" then
    vim.notify("No regex found under cursor", vim.log.levels.WARN)
    return
  end
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Regex: ' .. regex .. ' ',
    title_pos = 'center',
  }
  
  local win = vim.api.nvim_open_win(buf, true, opts)
  
  local function update_highlights()
    pcall(function()
      highlight_matches(buf, regex)
    end)
  end
  
  
  update_highlights()
  
  vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
    buffer = buf,
    callback = update_highlights,
  })
  
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>q<cr>', { silent = true })
  
  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = buf,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })
end

return M