local M = {}

local function format_relative_time(timestamp)
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

local function traverse_undotree(entries)
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

    local buffer_after = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}, "\n")

    -- Navigate to parent state (one undo back)
    success = pcall(function()
      vim.cmd("silent undo")
    end)
    if not success then
      goto continue
    end

    local buffer_before = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}, "\n")

    local diff = vim.diff(buffer_before, buffer_after, {
      result_type = "unified",
      ctxlen = 1,
    })

    local additions, deletions, ordinal = {}, {}, ""
    if diff then
      for line in (diff .. "\n"):gmatch("(.-)\n") do
        local prefix, content = line:sub(1, 1), line:sub(2, -1)
        if prefix == "+" then
          table.insert(additions, content)
          ordinal = ordinal .. content
        elseif prefix == "-" then
          table.insert(deletions, content)
          ordinal = ordinal .. content
        end
      end
    end

    -- Skip empty changes
    if #additions == 0 and #deletions == 0 then
      goto continue
    end

    table.insert(undolist, {
      seq = entry.seq,
      diff = diff or "",
      additions = additions,
      deletions = deletions,
      ordinal = ordinal,
      time = entry.time or 0,
    })

    -- Process alternate branches recursively
    if entry.alt then
      for _, elem in pairs(traverse_undotree(entry.alt)) do
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
  local undotree = vim.fn.undotree()
  if not undotree or not undotree.entries then
    return {}
  end

  -- Build the undo list with diffs
  local undolist = traverse_undotree(undotree.entries)

  -- Add the original state (sequence 0) if we have any undo history
  if #undolist > 0 then
    -- Add original state entry
    table.insert(undolist, 1, {
      seq = 0,
      diff = "",
      additions = {},
      deletions = {},
      ordinal = "",
      time = 0,
    })
  end

  -- Post-process to add undotree-style state markers
  local current_seq = undotree.seq_cur
  local seq_last = undotree.seq_last or current_seq

  -- Collect saved states
  local saved_states = {}
  local most_recent_saved_seq = 0

  local function collect_saved_states(entries)
    for _, entry in ipairs(entries) do
      if entry.save then
        saved_states[entry.seq] = true
        if entry.save > (saved_states.max_save or 0) then
          saved_states.max_save = entry.save
          most_recent_saved_seq = entry.seq
        end
      end
      if entry.alt then collect_saved_states(entry.alt) end
    end
  end

  if undotree.entries then collect_saved_states(undotree.entries) end

  -- Sort by sequence number descending (undotree shows latest first)
  table.sort(undolist, function(a, b) return a.seq > b.seq end)

  for _, entry in ipairs(undolist) do
    -- Apply undotree's marking system
    local seq_str = entry.seq == current_seq and string.format(">%d<", entry.seq)
        or entry.seq > current_seq and entry.seq <= seq_last and string.format("{%d}", entry.seq)
        or entry.seq == seq_last and entry.seq ~= current_seq and string.format("[%d]", entry.seq)
        or tostring(entry.seq)

    -- Add saved state markers
    local saved_marker = saved_states[entry.seq] and
        (entry.seq == most_recent_saved_seq and " S" or " s") or ""

    -- Format display string with diffstat
    local time_str = "(" .. format_relative_time(entry.time) .. ")"
    local diffstat = (#entry.additions > 0 and " +" .. #entry.additions or "") ..
        (#entry.deletions > 0 and " -" .. #entry.deletions or "")
    entry.display = string.format("%s %s%s%s", seq_str, time_str, saved_marker, diffstat)
  end

  -- Restore original state
  vim.cmd("silent undo " .. current_seq)
  vim.api.nvim_win_set_cursor(0, cursor)

  return undolist
end

local function filter_undolist(query, undolist)
  local results = {}
  for _, entry in ipairs(undolist) do
    if query == "" or
        entry.display:lower():find(query:lower(), 1, true) or
        (entry.ordinal or ""):lower():find(query:lower(), 1, true) then
      table.insert(results, entry.display)
    end
  end
  return results
end

function M.pick()
  local core = require("fzf-lua.core")
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
  for _, entry in ipairs(undolist) do
    entry_map[entry.display] = entry
  end

  local opts = {
    prompt = "Undo> ",
    exec_empty_query = true,
    actions = {
      ["default"] = function(selected)
        local entry = selected[1] and entry_map[selected[1]]
        if entry and entry.seq then
          vim.cmd("undo " .. entry.seq)
        end
      end,
    },
    preview = shell.stringify_cmd(function(items)
      local entry = items[1] and entry_map[items[1]]
      local bat_cmd = "echo %s | bat --language=diff --color=always --style=changes --paging=never"
      return entry and entry.diff ~= "" and
          string.format(bat_cmd, vim.fn.shellescape(entry.diff)) or
          "echo 'No diff available'"
    end, {}, "{}"),
    fzf_opts = {
      ["--no-multi"] = "",
      ["--preview-window"] = "right:50%",
    },
    winopts = {
      height = 0.8,
      width = 0.9,
      preview = { horizontal = "right:50%" },
    },
  }

  core.fzf_live(function(query_table)
    return filter_undolist(query_table and query_table[1] or "", undolist)
  end, opts)
end

return M
