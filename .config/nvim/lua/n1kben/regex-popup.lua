local M = {}

-- Define highlight groups for capture groups with maximum color distinction
local function setup_highlight_groups()
  local colors = {
    { fg = "#FFAAAA", bg = "#440000" }, -- Light Red on Dark Red
    { fg = "#AAFFAA", bg = "#004400" }, -- Light Green on Dark Green
    { fg = "#AACCFF", bg = "#001144" }, -- Light Blue on Dark Blue
    { fg = "#FFFFAA", bg = "#444400" }, -- Light Yellow on Dark Yellow
    { fg = "#FFAAFF", bg = "#440044" }, -- Light Magenta on Dark Magenta
    { fg = "#AAFFFF", bg = "#004444" }, -- Light Cyan on Dark Cyan
    { fg = "#FFCCAA", bg = "#442200" }, -- Light Orange on Dark Orange
    { fg = "#CCAAFF", bg = "#220044" }, -- Light Purple on Dark Purple
  }
  
  for i, color in ipairs(colors) do
    vim.api.nvim_set_hl(0, "RegexCapture" .. i, color)
  end
  
  -- Define highlight for full match (group 0) - underline + bold
  vim.api.nvim_set_hl(0, "RegexFullMatch", {
    underline = true,
    bold = true,
    sp = "#FFFFFF" -- underline color
  })
end

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
  -- Create separate namespaces for different highlight types
  local ns_full = vim.api.nvim_create_namespace("regex_full_match")
  local ns_groups = vim.api.nvim_create_namespace("regex_capture_groups")
  
  -- Clear existing highlights
  vim.api.nvim_buf_clear_namespace(buf, ns_full, 0, -1)
  vim.api.nvim_buf_clear_namespace(buf, ns_groups, 0, -1)
  
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
          // Add the full match (capture group 0)
          matches.push({
            line: lineIndex,
            start: match.index,
            finish: match.index + match[0].length,
            group: 0
          });
          
          // Add each capture group
          for (let i = 1; i < match.length; i++) {
            if (match[i] !== undefined) {
              const groupStart = line.indexOf(match[i], match.index);
              matches.push({
                line: lineIndex,
                start: groupStart,
                finish: groupStart + match[i].length,
                group: i
              });
            }
          }
          
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
      -- Separate full matches and capture groups
      local full_matches = {}
      local capture_groups = {}
      
      for _, match in ipairs(matches) do
        if match.group == 0 then
          table.insert(full_matches, match)
        else
          table.insert(capture_groups, match)
        end
      end
      
      -- Apply full match highlights first (underline + bold)
      for _, match in ipairs(full_matches) do
        vim.api.nvim_buf_set_extmark(buf, ns_full, match.line, match.start, {
          end_col = match.finish,
          hl_group = "RegexFullMatch",
          priority = 100 -- Lower priority so capture groups can override
        })
      end
      
      -- Apply capture group highlights (background colors)
      for _, match in ipairs(capture_groups) do
        local color_index = ((match.group - 1) % 8) + 1
        local highlight_group = "RegexCapture" .. color_index
        
        vim.api.nvim_buf_set_extmark(buf, ns_groups, match.line, match.start, {
          end_col = match.finish,
          hl_group = highlight_group,
          priority = 200 -- Higher priority so they show on top
        })
      end
    end
  end
end

function M.create_regex_split(regex)
  setup_highlight_groups()
  
  -- Create the main text buffer (top split)
  local text_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(text_buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(text_buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(text_buf, 'filetype', 'text')
  
  -- Create the regex input buffer (bottom split)
  local regex_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(regex_buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(regex_buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(regex_buf, 'filetype', 'regex')
  
  -- Set initial regex content
  vim.api.nvim_buf_set_lines(regex_buf, 0, -1, false, {regex})
  
  -- Open horizontal split
  vim.cmd('split')
  local text_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(text_win, text_buf)
  
  -- Create bottom split for regex input
  vim.cmd('split')
  local regex_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(regex_win, regex_buf)
  
  -- Resize the regex input window to be smaller
  vim.api.nvim_win_set_height(regex_win, 3)
  
  -- Focus on the text buffer
  vim.api.nvim_set_current_win(text_win)
  
  local function get_current_regex()
    local lines = vim.api.nvim_buf_get_lines(regex_buf, 0, -1, false)
    local current_regex = lines[1] or ""
    -- Remove surrounding slashes if present
    if current_regex:match("^/.*/$") then
      current_regex = current_regex:sub(2, -2)
    end
    return current_regex
  end
  
  local function update_highlights()
    local current_regex = get_current_regex()
    if current_regex ~= "" then
      pcall(function()
        highlight_matches(text_buf, current_regex)
      end)
    else
      vim.api.nvim_buf_clear_namespace(text_buf, -1, 0, -1)
    end
  end
  
  -- Update highlights when text changes
  vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
    buffer = text_buf,
    callback = update_highlights,
  })
  
  -- Update highlights when regex changes
  vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
    buffer = regex_buf,
    callback = update_highlights,
  })
  
  -- Initial highlight update
  update_highlights()
  
  -- Close both windows when switching to a different buffer (not just window)
  local function close_all()
    if vim.api.nvim_win_is_valid(text_win) then
      vim.api.nvim_win_close(text_win, true)
    end
    if vim.api.nvim_win_is_valid(regex_win) then
      vim.api.nvim_win_close(regex_win, true)
    end
  end
  
  -- Only close when actually switching to a different buffer, not just changing windows
  vim.api.nvim_create_autocmd('BufEnter', {
    callback = function()
      local current_buf = vim.api.nvim_get_current_buf()
      if current_buf ~= text_buf and current_buf ~= regex_buf then
        close_all()
        return true -- Remove this autocmd
      end
    end
  })
end

function M.show_regex_popup()
  local regex = get_word_under_cursor()
  
  if regex == "" then
    regex = "\\d+"  -- Default regex pattern
  end
  
  M.create_regex_split(regex)
end

return M