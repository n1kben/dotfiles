local M = {}

-- Traverse the undo tree and build diff entries just like telescope-undo
local function traverse_undotree(entries, level)
  local undolist = {}
  
  -- Process entries in reverse order (latest first)
  for i = #entries, 1, -1 do
    local entry = entries[i]
    
    -- Navigate to this undo state
    local success = pcall(function()
      vim.cmd("silent undo " .. entry.seq)
    end)
    if not success then
      goto continue
    end

    local buffer_after_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}
    local buffer_after = table.concat(buffer_after_lines, "\n")

    -- Navigate to parent state (one undo back)
    success = pcall(function()
      vim.cmd("silent undo")
    end)
    if not success then
      goto continue
    end
    
    local buffer_before_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}
    local buffer_before = table.concat(buffer_before_lines, "\n")

    -- Create diff using vim.diff
    local diff = vim.diff(buffer_before, buffer_after, {
      result_type = "unified",
      ctxlen = 1,
    })

    -- Extract additions and deletions for display stats
    local additions = {}
    local deletions = {}
    local ordinal = ""
    
    if diff then
      for line in (diff .. "\n"):gmatch("(.-)\n") do
        if line:sub(1, 1) == "+" then
          local content = line:sub(2, -1)
          table.insert(additions, content)
          ordinal = ordinal .. content
        elseif line:sub(1, 1) == "-" then
          local content = line:sub(2, -1)
          table.insert(deletions, content)
          ordinal = ordinal .. content
        end
      end
    end

    -- Skip empty changes
    if #additions == 0 and #deletions == 0 then
      goto continue
    end

    -- Create display string with diffstat
    local diffstat = ""
    if #additions > 0 then
      diffstat = "+" .. #additions
    end
    if #deletions > 0 then
      if diffstat ~= "" then
        diffstat = diffstat .. " "
      end
      diffstat = diffstat .. "-" .. #deletions
    end

    -- Create tree prefix for visual hierarchy
    local prefix = ""
    if level > 0 then
      prefix = string.rep("┆ ", level - 1)
      if i == #entries then
        prefix = prefix .. "└╴"
      else
        prefix = prefix .. "├╴"
      end
    end

    -- Format time
    local time_str = entry.time and os.date("%H:%M:%S", entry.time) or ""
    
    -- Create display entry
    local display = string.format("%sstate #%d %s %s", prefix, entry.seq, diffstat, time_str)
    
    table.insert(undolist, {
      seq = entry.seq,
      display = display,
      diff = diff or "",
      additions = additions,
      deletions = deletions,
      ordinal = ordinal,
      time = entry.time or 0,
      level = level,
    })

    -- Process alternate branches recursively
    if entry.alt then
      local alt_undolist = traverse_undotree(entry.alt, level + 1)
      for _, elem in pairs(alt_undolist) do
        table.insert(undolist, elem)
      end
    end

    ::continue::
  end
  
  return undolist
end

local function build_undolist()
  -- Save cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)
  
  -- Get undo tree
  local ut = vim.fn.undotree()
  if not ut or not ut.entries then
    return {}
  end
  
  -- Build the undo list with diffs
  local undolist = traverse_undotree(ut.entries, 0)
  
  -- Add the original state (sequence 0) if we have any undo history
  if #undolist > 0 then
    -- Navigate to sequence 1 to get the diff from original to first change
    local success = pcall(function()
      vim.cmd("silent undo 1")
    end)
    
    if success then
      local buffer_after_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}
      local buffer_after = table.concat(buffer_after_lines, "\n")
      
      -- Go to original state (before any changes)
      vim.cmd("silent undo 0")
      local buffer_before_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}
      local buffer_before = table.concat(buffer_before_lines, "\n")
      
      -- Create diff for original state
      local diff = vim.diff(buffer_before, buffer_after, {
        result_type = "unified",
        ctxlen = 1,
      })
      
      -- Extract additions and deletions
      local additions = {}
      local deletions = {}
      local ordinal = ""
      
      if diff then
        for line in (diff .. "\n"):gmatch("(.-)\n") do
          if line:sub(1, 1) == "+" then
            local content = line:sub(2, -1)
            table.insert(additions, content)
            ordinal = ordinal .. content
          elseif line:sub(1, 1) == "-" then
            local content = line:sub(2, -1)
            table.insert(deletions, content)
            ordinal = ordinal .. content
          end
        end
      end
      
      -- Create diffstat for original state
      local diffstat = ""
      if #additions > 0 then
        diffstat = "+" .. #additions
      end
      if #deletions > 0 then
        if diffstat ~= "" then
          diffstat = diffstat .. " "
        end
        diffstat = diffstat .. "-" .. #deletions
      end
      
      -- Add original state entry with no diff (it's the baseline)
      table.insert(undolist, 1, {
        seq = 0,
        display = "state #0 (original)",
        diff = "",  -- No diff for original state
        additions = {},
        deletions = {},
        ordinal = "",
        time = 0,
        level = 0,
      })
    end
  end
  
  -- Post-process to add undotree-style state markers
  local current_seq = ut.seq_cur
  local saved_seq = ut.save_cur or 0
  local seq_last = ut.seq_last or current_seq
  
  -- Sort by sequence number descending (undotree shows latest first)
  table.sort(undolist, function(a, b) return a.seq > b.seq end)
  
  for _, entry in ipairs(undolist) do
    local seq_str = ""
    
    -- Apply undotree's exact marking system:
    if entry.seq == current_seq then
      seq_str = string.format(">%d<", entry.seq)  -- Current state: >num<
    elseif entry.seq > current_seq and entry.seq <= seq_last then
      seq_str = string.format("{%d}", entry.seq)  -- Redo state: {num}
    elseif entry.seq == seq_last and entry.seq ~= current_seq then
      seq_str = string.format("[%d]", entry.seq)  -- Latest state: [num]
    else
      seq_str = tostring(entry.seq)  -- Regular state: num
    end
    
    -- Add saved state marker
    local saved_marker = ""
    if saved_seq > 0 and entry.seq == saved_seq then
      saved_marker = " S"  -- Last saved state gets S
    elseif saved_seq > 0 and entry.seq < saved_seq then
      -- Check if this is a saved state (multiple saves possible)
      saved_marker = " s"  -- Previous saved states get s
    end
    
    -- Format like undotree: "seq (time)" 
    local time_str = entry.time and entry.time > 0 and os.date("(%H:%M:%S)", entry.time) or "(original)"
    
    -- Remove tree prefix and recreate in undotree style
    entry.display = string.format("%s %s%s", seq_str, time_str, saved_marker)
    
    -- Keep diffstat for additional info
    local diffstat = ""
    if #entry.additions > 0 then
      diffstat = " +" .. #entry.additions
    end
    if #entry.deletions > 0 then
      diffstat = diffstat .. " -" .. #entry.deletions
    end
    if diffstat ~= "" then
      entry.display = entry.display .. diffstat
    end
  end
  
  -- Restore original state
  vim.cmd("silent undo " .. current_seq)
  vim.api.nvim_win_set_cursor(0, cursor)
  
  return undolist
end

local function get_buffer_state_at_seq(seq)
  -- Save current state
  local current_seq = vim.fn.undotree().seq_cur
  
  -- If it's the current sequence, just return current buffer
  if seq == current_seq then
    return vim.api.nvim_buf_get_lines(0, 0, -1, false)
  end
  
  -- Save current position and other state
  local save_cursor = vim.api.nvim_win_get_cursor(0)
  local save_view = vim.fn.winsaveview()
  
  -- Navigate to the requested sequence
  local success, lines = pcall(function()
    vim.cmd("silent undo " .. seq)
    local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    
    -- Restore to current state
    if current_seq ~= seq then
      vim.cmd("silent undo " .. current_seq)
    end
    
    return result
  end)
  
  -- Restore cursor position and view
  pcall(vim.api.nvim_win_set_cursor, 0, save_cursor)
  pcall(vim.fn.winrestview, save_view)
  
  if success and lines then
    return lines
  else
    -- Fallback: return current state
    return vim.api.nvim_buf_get_lines(0, 0, -1, false)
  end
end

local function create_diff(current_lines, undo_lines, seq)
  local current_seq = vim.fn.undotree().seq_cur
  local undotree = vim.fn.undotree()
  local saved_seq = undotree.save_cur or 0
  
  
  -- For preview, show diff from saved state (or empty if no saved state)
  local baseline_lines = {}
  local baseline_name = "empty"
  
  if saved_seq > 0 then
    baseline_lines = get_buffer_state_at_seq(saved_seq)
    baseline_name = string.format("saved state (seq %d)", saved_seq)
  end
  
  if #baseline_lines == 0 and #undo_lines == 0 then
    return "Empty buffer"
  elseif seq == saved_seq then
    return "This is the saved state"
  end
  
  -- Use bat for beautiful diff with syntax highlighting
  -- Create temporary files for bat diff
  local baseline_file = vim.fn.tempname()
  local undo_file = vim.fn.tempname()
  
  -- Get current buffer filetype for syntax highlighting
  local filetype = vim.bo.filetype
  local extension = ""
  if filetype == "lua" then
    extension = ".lua"
  elseif filetype == "javascript" then
    extension = ".js"
  elseif filetype == "typescript" then
    extension = ".ts"
  elseif filetype == "python" then
    extension = ".py"
  elseif filetype == "rust" then
    extension = ".rs"
  elseif filetype == "go" then
    extension = ".go"
  elseif filetype == "json" then
    extension = ".json"
  elseif filetype == "yaml" then
    extension = ".yaml"
  end
  
  baseline_file = baseline_file .. extension
  undo_file = undo_file .. extension
  
  -- Write content to temp files
  local baseline_content = table.concat(baseline_lines, "\n")
  local undo_content = table.concat(undo_lines, "\n")
  
  vim.fn.writefile(vim.split(baseline_content, "\n"), baseline_file)
  vim.fn.writefile(vim.split(undo_content, "\n"), undo_file)
  
  -- Use bat for diff with syntax highlighting
  local cmd = string.format("bat --diff --diff-context=1 --color=always --style=changes --paging=never %s %s", 
    vim.fn.shellescape(baseline_file), vim.fn.shellescape(undo_file))
  
  local result = vim.fn.system(cmd)
  
  -- Clean up temp files
  vim.fn.delete(baseline_file)
  vim.fn.delete(undo_file)
  
  if vim.v.shell_error == 0 and result ~= "" then
    -- Add header and return bat output
    local header = string.format("--- %s\n+++ seq %d\n\n", baseline_name, seq)
    return header .. result
  else
    return "No changes from " .. baseline_name
  end
end

function M.pick()
  local fzf = require("fzf-lua")
  local shell = require("fzf-lua.shell")
  
  if not vim.bo.modifiable then
    vim.notify("Current buffer is not modifiable", vim.log.levels.WARN)
    return
  end
  
  local undolist = build_undolist()
  if #undolist == 0 then
    vim.notify("No undo history available", vim.log.levels.INFO)
    return
  end

  -- Create entry mapping for lookups
  local entry_map = {}
  local items = {}
  
  for _, entry in ipairs(undolist) do
    entry_map[entry.display] = entry
    table.insert(items, entry.display)
  end

  local opts = {
    prompt = "Undo Tree> ",
    actions = {
      ["default"] = function(selected)
        if #selected > 0 then
          local item = selected[1]
          local entry = entry_map[item]
          if entry and entry.seq then
            vim.cmd("undo " .. entry.seq)
            vim.notify("Restored to undo state " .. entry.seq, vim.log.levels.INFO)
          end
        end
      end,
      ["ctrl-y"] = function(selected)
        if #selected > 0 then
          local item = selected[1]
          local entry = entry_map[item]
          if entry and entry.additions and #entry.additions > 0 then
            local register = '"'
            vim.fn.setreg(register, entry.additions, (#entry.additions > 1) and "V" or "v")
            vim.notify("Yanked additions to register " .. register, vim.log.levels.INFO)
          end
        end
      end,
      ["ctrl-d"] = function(selected)
        if #selected > 0 then
          local item = selected[1]
          local entry = entry_map[item]
          if entry and entry.deletions and #entry.deletions > 0 then
            local register = '"'
            vim.fn.setreg(register, entry.deletions, (#entry.deletions > 1) and "V" or "v")
            vim.notify("Yanked deletions to register " .. register, vim.log.levels.INFO)
          end
        end
      end,
    },
    -- Use fzf-lua's shell.stringify_cmd pattern like git commands  
    preview = shell.stringify_cmd(function(items)
      local entry = entry_map[items[1]]
      if not entry or not entry.diff or entry.diff == "" then
        return "echo 'No diff available'"
      end
      
      -- Pipe diff content directly to bat, no temp files needed
      return string.format("echo %s | bat --language=diff --color=always --style=changes --paging=never",
        vim.fn.shellescape(entry.diff))
    end, {}, "{}"),
    fzf_opts = {
      ["--no-multi"] = "",
      ["--preview-window"] = "right:50%",
      ["--bind"] = "ctrl-y:accept,ctrl-d:accept",
    },
    winopts = {
      height = 0.8,
      width = 0.9,
      preview = {
        layout = "horizontal",
        horizontal = "right:50%",
      },
    },
  }

  fzf.fzf_exec(items, opts)
end

return M