local M = {}

-- RegexLayout class similar to telescope's layout system
local RegexLayout = {}
RegexLayout.__index = RegexLayout

function RegexLayout:new(config)
  local self = setmetatable({}, RegexLayout)
  self.config = config or {}
  self.windows = {}
  return self
end

function RegexLayout:mount()
  -- Simple window dimensions
  local width = vim.o.columns - 4
  local height = vim.o.lines - 6
  local input_height = 3
  local gap = 2 -- More spacing between windows
  local main_height = height - input_height - gap
  
  -- Center positioning
  local col = 2
  local row = 2
  
  -- Create buffers
  local main_bufnr = vim.api.nvim_create_buf(false, true)
  local input_bufnr = vim.api.nvim_create_buf(false, true)
  
  -- Create main window
  local main_win = vim.api.nvim_open_win(main_bufnr, true, {
    relative = 'editor',
    width = width,
    height = main_height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Regex Tester ',
    title_pos = 'center',
  })
  
  -- Create input window
  local input_win = vim.api.nvim_open_win(input_bufnr, false, {
    relative = 'editor',
    width = width,
    height = input_height,
    row = row + main_height + gap,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })
  
  -- Configure buffers
  vim.api.nvim_buf_set_option(main_bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_option(main_bufnr, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(main_bufnr, 'filetype', 'text')
  
  vim.api.nvim_buf_set_option(input_bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_option(input_bufnr, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(input_bufnr, 'filetype', 'regex')
  
  -- Set initial content
  if self.config.initial_regex then
    vim.api.nvim_buf_set_lines(input_bufnr, 0, -1, false, {self.config.initial_regex})
  end
  
  -- Store window information
  self.windows.main = {
    winid = main_win,
    bufnr = main_bufnr,
  }
  
  self.windows.input = {
    winid = input_win,
    bufnr = input_bufnr,
  }
  
  -- Focus main window initially
  vim.api.nvim_set_current_win(main_win)
  
  -- Set up keymaps for navigation between windows
  self:setup_keymaps()
end

function RegexLayout:setup_keymaps()
  if not self.windows.main or not self.windows.input then
    return
  end
  
  local main_bufnr = self.windows.main.bufnr
  local input_bufnr = self.windows.input.bufnr
  local main_winid = self.windows.main.winid
  local input_winid = self.windows.input.winid
  
  -- Keymap options
  local opts = { noremap = true, silent = true, buffer = true }
  
  -- Main window keymaps
  vim.api.nvim_buf_set_keymap(main_bufnr, 'n', '<C-j>', '', {
    noremap = true,
    silent = true,
    callback = function()
      if vim.api.nvim_win_is_valid(input_winid) then
        vim.api.nvim_set_current_win(input_winid)
      end
    end
  })
  
  vim.api.nvim_buf_set_keymap(main_bufnr, 'n', 'q', '', {
    noremap = true,
    silent = true,
    callback = function()
      self:unmount()
    end
  })
  
  -- Input window keymaps
  vim.api.nvim_buf_set_keymap(input_bufnr, 'n', '<C-k>', '', {
    noremap = true,
    silent = true,
    callback = function()
      if vim.api.nvim_win_is_valid(main_winid) then
        vim.api.nvim_set_current_win(main_winid)
      end
    end
  })
  
  vim.api.nvim_buf_set_keymap(input_bufnr, 'i', '<C-k>', '', {
    noremap = true,
    silent = true,
    callback = function()
      if vim.api.nvim_win_is_valid(main_winid) then
        vim.api.nvim_set_current_win(main_winid)
      end
    end
  })
  
  -- Add <C-j> mapping for input window to move down to main window (same as <C-k> but intuitive)
  vim.api.nvim_buf_set_keymap(input_bufnr, 'n', '<C-j>', '', {
    noremap = true,
    silent = true,
    callback = function()
      if vim.api.nvim_win_is_valid(main_winid) then
        vim.api.nvim_set_current_win(main_winid)
      end
    end
  })
  
  vim.api.nvim_buf_set_keymap(input_bufnr, 'i', '<C-j>', '', {
    noremap = true,
    silent = true,
    callback = function()
      if vim.api.nvim_win_is_valid(main_winid) then
        vim.api.nvim_set_current_win(main_winid)
      end
    end
  })
  
  vim.api.nvim_buf_set_keymap(input_bufnr, 'n', 'q', '', {
    noremap = true,
    silent = true,
    callback = function()
      self:unmount()
    end
  })
end

function RegexLayout:unmount()
  -- Clear all autocmds that might reference this layout
  pcall(vim.api.nvim_del_augroup_by_name, "RegexPopupClose")
  
  -- Close all windows and clean up
  for name, window in pairs(self.windows) do
    if window.winid and vim.api.nvim_win_is_valid(window.winid) then
      vim.api.nvim_win_close(window.winid, true)
    end
  end
  self.windows = {}
  
  -- Clear global reference
  if M._current_layout == self then
    M._current_layout = nil
  end
end

function RegexLayout:update()
  -- Handle window resizing if needed
  -- For now, we'll just recreate the layout
  self:unmount()
  self:mount()
end

function RegexLayout:get_current_regex()
  if not self.windows.input or not self.windows.input.bufnr then
    return ""
  end
  
  local lines = vim.api.nvim_buf_get_lines(self.windows.input.bufnr, 0, -1, false)
  local current_regex = lines[1] or ""
  
  -- Remove surrounding slashes if present
  if current_regex:match("^/.*/$") then
    current_regex = current_regex:sub(2, -2)
  end
  
  return current_regex
end

function RegexLayout:update_input_title(regex)
  -- No title on input window - content is visible directly
end

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

function M.create_regex_window(regex)
  setup_highlight_groups()
  
  -- Create layout with initial regex
  local layout = RegexLayout:new({
    initial_regex = regex
  })
  
  -- Mount the layout
  layout:mount()
  
  -- Get references to the buffers for easier access
  local text_buf = layout.windows.main.bufnr
  local regex_buf = layout.windows.input.bufnr
  
  local function update_highlights()
    local current_regex = layout:get_current_regex()
    if current_regex ~= "" then
      pcall(function()
        highlight_matches(text_buf, current_regex)
      end)
      layout:update_input_title(current_regex)
    else
      vim.api.nvim_buf_clear_namespace(text_buf, -1, 0, -1)
      layout:update_input_title("")
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
  
  -- Enhanced window closing behavior
  local function close_all()
    layout:unmount()
  end
  
  -- Store layout for potential cleanup
  M._current_layout = layout
  
  -- Close only when actually leaving to edit a different file
  local group = vim.api.nvim_create_augroup("RegexPopupClose", { clear = true })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function()
      local current_buf = vim.api.nvim_get_current_buf()
      
      -- Only close if we enter a buffer that's not one of our regex buffers
      -- AND that buffer is associated with a real file or different functionality
      if current_buf ~= text_buf and current_buf ~= regex_buf then
        local buftype = vim.api.nvim_buf_get_option(current_buf, 'buftype')
        local filetype = vim.api.nvim_buf_get_option(current_buf, 'filetype')
        
        -- Close if it's a real file or a different kind of special buffer
        if buftype == '' or (buftype ~= 'nofile' and filetype ~= 'regex') then
          close_all()
          vim.api.nvim_del_augroup_by_id(group)
          M._current_layout = nil
        end
      end
    end
  })
  
  -- Handle vim resize
  vim.api.nvim_create_autocmd('VimResized', {
    group = group,
    callback = function()
      if layout then
        layout:update()
      end
    end
  })
end

function M.show_regex_popup()
  local regex = get_word_under_cursor()
  
  if regex == "" then
    regex = "\\d+"  -- Default regex pattern
  end
  
  M.create_regex_window(regex)
end

-- Function to close the current regex popup
function M.close_regex_popup()
  if M._current_layout then
    M._current_layout:unmount()
    M._current_layout = nil
  end
end

-- Function to toggle the regex popup
function M.toggle_regex_popup()
  if M._current_layout then
    M.close_regex_popup()
  else
    M.show_regex_popup()
  end
end

return M