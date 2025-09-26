local M = {}

-- Default configuration
M.config = {
  dual_patterns = {},
  -- How to search for alternates: "all" | "first"
  search_mode = "all",
  -- Show picker even for single result
  always_show_picker = false,
  -- Enable debug logging
  debug = false,
}

-- Cache for compiled patterns
M._cache = {
  patterns = {},
  compiled = {},
}

-- Logging utility
local function log(msg, level)
  if M.config.debug then
    vim.notify("[alternate] " .. msg, level or vim.log.levels.INFO)
  end
end

-- Escape pattern for lua matching
local function escape_pattern(str)
  return str:gsub("([%.%+%-%?%[%]%(%)%^%$%%])", "%%%1")
end

-- Compile a glob pattern to lua pattern
local function compile_pattern(pattern)
  if M._cache.compiled[pattern] then
    return M._cache.compiled[pattern]
  end

  local escaped = escape_pattern(pattern)
  local lua_pattern = escaped:gsub("%*", "(.+)")
  lua_pattern = "^" .. lua_pattern .. "$"

  M._cache.compiled[pattern] = lua_pattern
  return lua_pattern
end

-- Extract wildcard captures from filename
local function extract_wildcards(filename, pattern)
  local lua_pattern = compile_pattern(pattern)
  local captures = { filename:match(lua_pattern) }
  return #captures > 0 and captures or nil
end

-- Build filename from pattern and captures
local function build_filename(pattern, captures)
  local result = pattern
  for _, capture in ipairs(captures) do
    result = result:gsub("%*", capture, 1)
  end
  return result
end

-- Build the patterns lookup table
local function build_patterns()
  M._cache.patterns = {}

  for _, rule in ipairs(M.config.dual_patterns) do
    local pattern1, pattern2 = rule[1], rule[2]
    local name1, name2 = rule[3] or "Alternate", rule[4] or "Alternate"

    -- Forward mapping
    if not M._cache.patterns[pattern1] then
      M._cache.patterns[pattern1] = {}
    end
    table.insert(M._cache.patterns[pattern1], {
      target = pattern2,
      name = name2
    })

    -- Reverse mapping
    if not M._cache.patterns[pattern2] then
      M._cache.patterns[pattern2] = {}
    end
    table.insert(M._cache.patterns[pattern2], {
      target = pattern1,
      name = name1
    })
  end

  log("Built patterns: " .. vim.inspect(M._cache.patterns))
end

-- Find alternate files for a given file path
local function find_alternates_for_file(filepath)
  local alternates = {}
  local filename = vim.fn.fnamemodify(filepath, ":t")
  local directory = vim.fn.fnamemodify(filepath, ":h")

  log("Finding alternates for: " .. filepath)
  log("Filename: " .. filename .. ", Directory: " .. directory)

  -- Check each pattern
  for source_pattern, targets in pairs(M._cache.patterns) do
    local captures = extract_wildcards(filename, source_pattern)

    if captures then
      log("Pattern '" .. source_pattern .. "' matched with captures: " .. vim.inspect(captures))

      for _, target in ipairs(targets) do
        local alt_filename = build_filename(target.target, captures)
        local alt_path = directory == "." and alt_filename or (directory .. "/" .. alt_filename)

        log("Checking alternate: " .. alt_path)

        -- Check if file exists
        if vim.fn.filereadable(alt_path) == 1 or vim.fn.isdirectory(alt_path) == 1 then
          table.insert(alternates, {
            path = alt_path,
            filename = alt_filename,
            name = target.name,
            pattern = target.target,
          })
          log("Found: " .. alt_path)

          if M.config.search_mode == "first" then
            return alternates
          end
        else
          -- Also check in common locations relative to project root
          local root_markers = { ".git", "package.json", "Cargo.toml", "go.mod" }
          for _, marker in ipairs(root_markers) do
            local root = vim.fn.finddir(marker, ".;") or vim.fn.findfile(marker, ".;")
            if root ~= "" then
              local project_root = vim.fn.fnamemodify(root, ":h")
              local alt_from_root = project_root .. "/" .. alt_path
              if vim.fn.filereadable(alt_from_root) == 1 then
                table.insert(alternates, {
                  path = alt_from_root,
                  filename = alt_filename,
                  name = target.name,
                  pattern = target.target,
                })
                log("Found in project root: " .. alt_from_root)
                break
              end
            end
          end
        end
      end
    end
  end

  return alternates
end

-- Open file with specified command
local function open_file(filepath, command)
  local commands = {
    edit = "edit",
    split = "split",
    vsplit = "vsplit",
    tab = "tabedit",
  }

  local cmd = commands[command] or "edit"
  vim.cmd(cmd .. " " .. vim.fn.fnameescape(filepath))
end

-- Show picker for alternates
local function show_picker(alternates)
  if #alternates == 0 then
    vim.notify("No alternate files found", vim.log.levels.INFO)
    return
  end

  -- If only one alternate and not forcing picker, open directly
  if #alternates == 1 and not M.config.always_show_picker then
    open_file(alternates[1].path, "edit")
    return
  end

  -- Prepare display items
  local items = {}
  for _, alt in ipairs(alternates) do
    local display = string.format("[%s] %s", alt.name, alt.path)
    table.insert(items, display)
  end

  -- Show file picker
  vim.ui.select(items, {
    prompt = "Select alternate file:",
    format_item = function(item) return item end,
  }, function(choice, idx)
    if not choice or not idx then
      return
    end

    local selected = alternates[idx]

    -- Show action picker
    vim.ui.select({
      "Edit in current window",
      "Open in horizontal split",
      "Open in vertical split",
      "Open in new tab",
    }, {
      prompt = "How to open " .. selected.filename .. ":",
    }, function(action, action_idx)
      if not action or not action_idx then
        return
      end

      local actions = { "edit", "split", "vsplit", "tab" }
      open_file(selected.path, actions[action_idx])
    end)
  end)
end

-- Main function to find and switch to alternate files
function M.find_alternates()
  local current_file = vim.fn.expand("%:.")

  if current_file == "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return
  end

  local alternates = find_alternates_for_file(current_file)
  show_picker(alternates)
end

-- Quick switch to first alternate (useful for mappings)
function M.switch()
  local current_file = vim.fn.expand("%:.")

  if current_file == "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return
  end

  local alternates = find_alternates_for_file(current_file)

  if #alternates > 0 then
    open_file(alternates[1].path, "edit")
  else
    vim.notify("No alternate files found", vim.log.levels.INFO)
  end
end

-- Setup function
function M.setup(opts)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Build pattern cache
  build_patterns()

  -- Create user commands
  vim.api.nvim_create_user_command("Alternate", function()
    M.find_alternates()
  end, { desc = "Find alternate files" })

  vim.api.nvim_create_user_command("AlternateSwitch", function()
    M.switch()
  end, { desc = "Switch to first alternate file" })

  -- Optional: Create a keymap for quick switching
  -- vim.keymap.set("n", "<leader>a", M.switch, { desc = "Switch to alternate file" })

  log("Alternate files plugin initialized with " .. #M.config.dual_patterns .. " patterns")
end

-- Add a pattern dynamically
function M.add_pattern(pattern1, pattern2, name1, name2)
  table.insert(M.config.dual_patterns, { pattern1, pattern2, name1, name2 })
  build_patterns()
end

-- List all patterns (useful for debugging)
function M.list_patterns()
  for pattern, targets in pairs(M._cache.patterns) do
    print("Pattern: " .. pattern)
    for _, target in ipairs(targets) do
      print("  -> " .. target.target .. " (" .. target.name .. ")")
    end
  end
end

return M
