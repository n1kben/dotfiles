local M = {}

-- Configuration
M.config = {
  patterns = {},
  debug = false,
}

-- Convert glob pattern to lua pattern
local function glob_to_lua_pattern(glob)
  local pattern = glob
  -- Handle character classes [abc] or [a-z]
  pattern = pattern:gsub("%[([^%]]+)%]", function(chars)
    -- Keep character classes as-is for lua patterns
    return "[" .. chars .. "]"
  end)
  -- Escape special characters except * and ** and []
  pattern = pattern:gsub("([%.%+%-%?%(%)%^%$%%])", function(c)
    -- Don't escape - if it's inside brackets (already handled above)
    if c == "-" then return c end
    return "%" .. c
  end)
  -- Handle ** (any number of directories)
  pattern = pattern:gsub("%*%*", ".__PATH__")
  -- Handle * (single segment)
  pattern = pattern:gsub("%*", "([^/]+)")
  -- Replace ** placeholder
  pattern = pattern:gsub("%.%_%_PATH%_%_", "(.*)")
  return "^" .. pattern .. "$"
end

-- Extract captures from a path using a pattern
local function extract_captures(path, pattern)
  local lua_pattern = glob_to_lua_pattern(pattern)
  local captures = { path:match(lua_pattern) }

  if #captures > 0 then
    if M.config.debug then
      print(string.format("[alternate] Pattern '%s' matched '%s'", pattern, path))
    end
    return captures
  end

  return nil
end

-- Build a path from a pattern and captures
local function build_path(pattern, captures)
  if not captures or #captures == 0 then
    return pattern
  end

  local result = pattern
  local capture_index = 1

  -- Replace ** first (if any)
  result = result:gsub("%*%*", function()
    local capture = captures[capture_index] or ""
    capture_index = capture_index + 1
    return capture
  end)

  -- Replace * placeholders
  result = result:gsub("%*", function()
    local capture = captures[capture_index] or ""
    capture_index = capture_index + 1
    return capture
  end)

  return result
end

-- Find alternates for a file
function M.find_alternates()
  local current_file = vim.fn.expand("%:.") -- Path relative to cwd

  if current_file == "" then
    vim.notify("[alternate] No file in current buffer", vim.log.levels.WARN)
    return
  end

  -- Extract just the filename for simple patterns
  local filename = vim.fn.expand("%:t")
  local directory = vim.fn.expand("%:h")

  if M.config.debug then
    print("[alternate] Current file: " .. current_file)
    print("[alternate] Filename: " .. filename)
    print("[alternate] Directory: " .. directory)
    print("[alternate] Working directory: " .. vim.fn.getcwd())
  end

  local alternates = {}
  local seen = {}

  -- Check each dual pattern
  for _, dual in ipairs(M.config.patterns) do
    local pattern1 = dual[1][1]
    local name1 = dual[1][2]
    local pattern2 = dual[2][1]
    local name2 = dual[2][2]

    -- Check both the full relative path and just the filename
    local paths_to_check = { current_file }

    -- If pattern doesn't contain /, also check against just the filename
    if not pattern1:match("/") and not pattern2:match("/") then
      paths_to_check = { filename }
    end

    for _, check_path in ipairs(paths_to_check) do
      -- Try pattern1 -> pattern2
      local captures = extract_captures(check_path, pattern1)
      if captures then
        local target_name = build_path(pattern2, captures)
        -- Build full path if we matched just filename
        local target_path = check_path == filename
            and (directory == "." and target_name or directory .. "/" .. target_name)
            or target_name

        if M.config.debug then
          print(string.format("[alternate] Checking: %s", target_path))
        end
        if vim.fn.filereadable(target_path) == 1 and not seen[target_path] then
          seen[target_path] = true
          table.insert(alternates, {
            path = target_path,
            name = name2,
          })
          if M.config.debug then
            print("[alternate] Found: " .. target_path)
          end
        end
      end

      -- Try pattern2 -> pattern1
      captures = extract_captures(check_path, pattern2)
      if captures then
        local target_name = build_path(pattern1, captures)
        -- Build full path if we matched just filename
        local target_path = check_path == filename
            and (directory == "." and target_name or directory .. "/" .. target_name)
            or target_name

        if M.config.debug then
          print(string.format("[alternate] Checking: %s", target_path))
        end
        if vim.fn.filereadable(target_path) == 1 and not seen[target_path] then
          seen[target_path] = true
          table.insert(alternates, {
            path = target_path,
            name = name1,
          })
          if M.config.debug then
            print("[alternate] Found: " .. target_path)
          end
        end
      end
    end
  end

  -- Show results
  if #alternates == 0 then
    vim.notify("[alternate] No alternate files found", vim.log.levels.INFO)
    return
  end

  return alternates
end

function M.select_alternate()
  local alternates = M.find_alternates()
  if alternates == nil then return end
  local items = {}
  for _, alt in ipairs(alternates) do
    table.insert(items, string.format("[%s] %s", alt.name, alt.path))
  end

  vim.ui.select(items, {
    prompt = "Select alternate file:",
  }, function(_, idx)
    if idx then
      vim.cmd("edit " .. vim.fn.fnameescape(alternates[idx].path))
    end
  end)
end

-- Quick switch to first alternate
function M.switch_alternate()
  local alternates = M.find_alternates()
  if alternates == nil then return end
  if M.config.debug then
    print("[alternate] Switching to " .. alternates[1].path)
  end
  vim.cmd("edit " .. vim.fn.fnameescape(alternates[1].path))
end

-- Setup
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Commands
  vim.api.nvim_create_user_command("Alternate", M.select_alternate,
    { desc = "Find alternate files" })
  vim.api.nvim_create_user_command("AlternateSwitch", M.switch_alternate,
    { desc = "Switch to first alternate file" })

  -- Keymaps
  vim.keymap.set("n", "<leader>a", ":AlternateSwitch<CR>", { desc = "Alternate: Switch to first alternate file" })
  vim.keymap.set("n", "<leader>A", ":Alternate<CR>", { desc = "Alternate: Find alternate files" })
end

return M
