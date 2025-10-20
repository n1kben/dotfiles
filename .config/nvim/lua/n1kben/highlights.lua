-- lua/n1kben/highlights.lua
local M = {}

-- Get all highlight groups under cursor
local function get_highlight_under_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2] -- Convert to 0-based indexing
  
  local highlights = {}
  
  -- Get treesitter highlights
  if vim.treesitter.highlighter and vim.treesitter.highlighter.active then
    local bufnr = vim.api.nvim_get_current_buf()
    local highlighter = vim.treesitter.highlighter.active[bufnr]
    
    if highlighter then
      highlighter.tree:for_each_tree(function(tstree, tree)
        if not tstree then return end
        
        local root = tstree:root()
        local query = highlighter:get_query(tree:lang())
        
        if query then
          for id, node, metadata in query:iter_captures(root, bufnr, row, row + 1) do
            local start_row, start_col, end_row, end_col = node:range()
            
            -- Check if cursor is within this node
            if (start_row < row or (start_row == row and start_col <= col)) and
               (end_row > row or (end_row == row and end_col > col)) then
              local capture_name = query.captures[id]
              local hl_group = "@" .. capture_name .. "." .. tree:lang()
              table.insert(highlights, {
                type = "treesitter",
                group = hl_group,
                capture = capture_name,
                lang = tree:lang(),
                range = { start_row, start_col, end_row, end_col }
              })
            end
          end
        end
      end)
    end
  end
  
  -- Get syntax highlights
  local synID = vim.fn.synID(cursor[1], cursor[2] + 1, 1)
  if synID > 0 then
    local syn_name = vim.fn.synIDattr(synID, "name")
    local trans_synID = vim.fn.synIDtrans(synID)
    local trans_name = vim.fn.synIDattr(trans_synID, "name")
    
    table.insert(highlights, {
      type = "syntax",
      group = syn_name,
      trans_group = trans_name ~= syn_name and trans_name or nil
    })
  end
  
  -- Get buffer-local highlights (extmarks)
  local bufnr = vim.api.nvim_get_current_buf()
  local namespaces = vim.api.nvim_get_namespaces()
  
  for name, ns_id in pairs(namespaces) do
    local extmarks = vim.api.nvim_buf_get_extmarks(
      bufnr, ns_id, 
      { row, 0 }, 
      { row, -1 }, 
      { details = true }
    )
    
    for _, extmark in ipairs(extmarks) do
      local mark_row, mark_col = extmark[2], extmark[3]
      local details = extmark[4]
      
      if details.hl_group and mark_col <= col then
        -- Check if this extmark covers the cursor position
        local end_col = details.end_col or (mark_col + 1)
        if col < end_col then
          table.insert(highlights, {
            type = "extmark",
            group = details.hl_group,
            namespace = name,
            range = { mark_row, mark_col, mark_row, end_col }
          })
        end
      end
    end
  end
  
  return highlights
end

-- Get highlight group definition
local function get_highlight_definition(hl_group)
  local ok, hl_def = pcall(vim.api.nvim_get_hl_by_name, hl_group, true)
  if not ok then
    return nil
  end
  
  local def = {}
  
  -- Convert numeric values to hex
  if hl_def.foreground then
    def.fg = string.format("#%06x", hl_def.foreground)
  end
  if hl_def.background then
    def.bg = string.format("#%06x", hl_def.background)
  end
  if hl_def.special then
    def.sp = string.format("#%06x", hl_def.special)
  end
  
  -- Boolean attributes
  if hl_def.bold then def.bold = true end
  if hl_def.italic then def.italic = true end
  if hl_def.underline then def.underline = true end
  if hl_def.undercurl then def.undercurl = true end
  if hl_def.strikethrough then def.strikethrough = true end
  if hl_def.reverse then def.reverse = true end
  
  return def
end

-- Format highlight information for display
local function format_highlight_info(highlights)
  if #highlights == 0 then
    return "No highlights found under cursor"
  end
  
  local lines = { "Highlights under cursor:" }
  table.insert(lines, "")
  
  for i, hl in ipairs(highlights) do
    table.insert(lines, string.format("%d. %s (%s)", i, hl.group, hl.type))
    
    if hl.trans_group then
      table.insert(lines, string.format("   → %s (translated)", hl.trans_group))
    end
    
    if hl.capture then
      table.insert(lines, string.format("   Capture: %s", hl.capture))
    end
    
    if hl.lang then
      table.insert(lines, string.format("   Language: %s", hl.lang))
    end
    
    if hl.namespace then
      table.insert(lines, string.format("   Namespace: %s", hl.namespace))
    end
    
    -- Get highlight definition
    local def = get_highlight_definition(hl.group)
    if def then
      local def_parts = {}
      if def.fg then table.insert(def_parts, "fg=" .. def.fg) end
      if def.bg then table.insert(def_parts, "bg=" .. def.bg) end
      if def.sp then table.insert(def_parts, "sp=" .. def.sp) end
      if def.bold then table.insert(def_parts, "bold") end
      if def.italic then table.insert(def_parts, "italic") end
      if def.underline then table.insert(def_parts, "underline") end
      if def.undercurl then table.insert(def_parts, "undercurl") end
      if def.strikethrough then table.insert(def_parts, "strikethrough") end
      if def.reverse then table.insert(def_parts, "reverse") end
      
      if #def_parts > 0 then
        table.insert(lines, "   Definition: " .. table.concat(def_parts, " "))
      end
    end
    
    table.insert(lines, "")
  end
  
  return table.concat(lines, "\n")
end

-- Show highlight info in a floating window
function M.show_highlight_info()
  local highlights = get_highlight_under_cursor()
  local content = format_highlight_info(highlights)
  
  -- Calculate window size
  local lines = vim.split(content, "\n")
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.min(width + 4, vim.o.columns - 10)
  local height = math.min(#lines + 2, vim.o.lines - 10)
  
  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'highlight-info')
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'cursor',
    width = width,
    height = height,
    col = 1,
    row = 1,
    style = 'minimal',
    border = 'rounded',
    title = 'Highlight Under Cursor',
    title_pos = 'center'
  })
  
  -- Set up highlighting for the content
  local ns = vim.api.nvim_create_namespace('highlight_info')
  for i, line in ipairs(lines) do
    if line:match("^%d+%.") then
      -- Highlight the main highlight group name
      local hl_group = line:match("^%d+%. ([^%s]+)")
      if hl_group then
        local start_col = line:find(hl_group, 1, true) - 1
        vim.api.nvim_buf_add_highlight(buf, ns, hl_group, i - 1, start_col, start_col + #hl_group)
      end
    elseif line:match("^   →") then
      -- Highlight translated group
      vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
    elseif line:match("^   Definition:") then
      -- Highlight definition line
      vim.api.nvim_buf_add_highlight(buf, ns, 'String', i - 1, 0, -1)
    end
  end
  
  -- Close on escape or q
  local function close_win()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  
  vim.keymap.set('n', '<Esc>', close_win, { buffer = buf, nowait = true })
  vim.keymap.set('n', 'q', close_win, { buffer = buf, nowait = true })
end

-- Setup function
function M.setup()
  -- Command
  vim.api.nvim_create_user_command("HighlightUnderCursor", M.show_highlight_info, {
    desc = "Show highlight groups under cursor"
  })
  
  -- Keymap suggestion: <leader>hi (highlight info)
  vim.keymap.set('n', '<leader>hi', M.show_highlight_info, { 
    desc = "Show highlight groups under cursor" 
  })
end

return M