-- lua/git-status.lua
local M = {}

-- Default configuration
M.config = {}

-- Setup highlight groups for git status
local function setup_highlights()
  -- Section headers - use Normal foreground for better theme compatibility
  vim.api.nvim_set_hl(0, "GitStatusHeader", { link = "Normal" })

  -- File statuses - use vim's diagnostic colors
  vim.api.nvim_set_hl(0, "GitStatusStaged", { link = "DiagnosticOk" })       -- Green for staged changes
  vim.api.nvim_set_hl(0, "GitStatusModified", { link = "DiagnosticWarn" })   -- Orange/yellow for modified
  vim.api.nvim_set_hl(0, "GitStatusUntracked", { link = "DiagnosticError" }) -- Red for untracked

  -- Instructions and empty messages - use comment color
  vim.api.nvim_set_hl(0, "GitStatusInstructions", { link = "Comment" })
  vim.api.nvim_set_hl(0, "GitStatusEmpty", { link = "Comment" })

  -- Branch info - use Normal color for theme compatibility
  vim.api.nvim_set_hl(0, "GitStatusBranch", { link = "Normal" })
end

-- Git status sections with their display names
local SECTIONS = {
  { key = "staged",    name = "Changes to be committed:" },
  { key = "modified",  name = "Changes not staged for commit:" },
  { key = "untracked", name = "Untracked files:" },
}

-- Get git repository root directory
local function get_git_root()
  local root_output = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error == 0 then
    return root_output:gsub("%s+$", "") -- trim trailing whitespace
  end
  return nil
end

-- Convert relative file path to absolute path from git root
local function get_absolute_path(relative_path)
  local git_root = get_git_root()
  if git_root then
    return git_root .. "/" .. relative_path
  end
  return relative_path -- fallback to relative path if git root not found
end

-- Convert git root relative path to current working directory relative path
local function get_cwd_relative_path(git_relative_path)
  local git_root = get_git_root()
  local cwd = vim.fn.getcwd()
  
  if not git_root then
    return git_relative_path
  end
  
  -- Get absolute path of the file
  local absolute_path = git_root .. "/" .. git_relative_path
  
  -- Convert to relative path from current working directory
  -- fnamemodify with ":." gives relative path from cwd, but might return absolute if outside
  local relative_path = vim.fn.fnamemodify(absolute_path, ":.")
  
  -- If it's still absolute (starts with /), calculate manual relative path
  if relative_path:match("^/") then
    -- Calculate relative path manually
    local cwd_parts = vim.split(cwd, "/")
    local file_parts = vim.split(absolute_path, "/")
    
    -- Find common prefix
    local common_len = 0
    for i = 1, math.min(#cwd_parts, #file_parts) do
      if cwd_parts[i] == file_parts[i] then
        common_len = i
      else
        break
      end
    end
    
    -- Build relative path
    local up_dirs = #cwd_parts - common_len
    local down_parts = {}
    for i = common_len + 1, #file_parts do
      table.insert(down_parts, file_parts[i])
    end
    
    if up_dirs > 0 then
      local up_path = string.rep("../", up_dirs):sub(1, -2) -- remove trailing /
      if #down_parts > 0 then
        relative_path = up_path .. "/" .. table.concat(down_parts, "/")
      else
        relative_path = up_path
      end
    else
      relative_path = table.concat(down_parts, "/")
    end
  end
  
  return relative_path
end

-- Run git command from git root directory
local function run_git_command(cmd)
  local git_root = get_git_root()
  if git_root then
    -- Use -C flag to run git command from specific directory
    local git_cmd = "git -C " .. vim.fn.shellescape(git_root) .. " " .. cmd:gsub("^git ", "")
    return vim.fn.system(git_cmd)
  else
    return vim.fn.system(cmd)
  end
end

-- Parse git command output and add files to result table
local function parse_git_output(output, section_key, result)
  if vim.v.shell_error == 0 and output ~= "" then
    for line in output:gmatch("[^\r\n]+") do
      if line ~= "" then
        if section_key == "untracked" then
          local display_file = get_cwd_relative_path(line)
          table.insert(result[section_key], { status = "??", file = line, display_file = display_file })
        else
          local status, file = line:match("^(%S+)%s+(.+)$")
          if status and file then
            local display_file = get_cwd_relative_path(file)
            table.insert(result[section_key], { status = status, file = file, display_file = display_file })
          end
        end
      end
    end
  end
end

local function parse_git_status()
  local result = { staged = {}, modified = {}, untracked = {} }

  -- Get staged files
  local staged_output = run_git_command("git diff --name-status --cached")
  parse_git_output(staged_output, "staged", result)

  -- Get modified files  
  local modified_output = run_git_command("git diff --name-status")
  parse_git_output(modified_output, "modified", result)

  -- Get untracked files
  local untracked_output = run_git_command("git ls-files --others --exclude-standard")
  parse_git_output(untracked_output, "untracked", result)

  return result
end

-- Format git status display content
local function format_git_status_content(git_data)
  local lines = {}
  local file_map = {}      -- Map line numbers to files
  local highlight_map = {} -- Map line numbers to highlight groups
  local line_num = 1

  -- Get current branch
  local branch_output = run_git_command("git branch --show-current 2>/dev/null")
  local branch = branch_output:gsub("%s+", "") -- trim whitespace
  if branch == "" then
    branch = "HEAD"
  end

  -- Add branch info
  table.insert(lines, "Branch: " .. branch)
  highlight_map[line_num] = "GitStatusBranch"
  line_num = line_num + 1

  table.insert(lines, "")
  line_num = line_num + 1

  -- Add help text at top
  table.insert(lines,
    "Press <CR> for diff, gd to open file, <Tab> to stage/unstage, <BS> to checkout/delete")
  highlight_map[line_num] = "GitStatusInstructions"
  line_num = line_num + 1

  table.insert(lines, "")
  line_num = line_num + 1

  -- Always show all sections
  for _, section in ipairs(SECTIONS) do
    local files = git_data[section.key]

    table.insert(lines, section.name)
    highlight_map[line_num] = "GitStatusHeader"
    line_num = line_num + 1

    if #files > 0 then
      for _, item in ipairs(files) do
        local display_line = string.format("  %s %s", item.status, item.display_file or item.file)
        table.insert(lines, display_line)
        file_map[line_num] = item.file

        -- Set highlight based on section
        if section.key == "staged" then
          highlight_map[line_num] = "GitStatusStaged"
        elseif section.key == "modified" then
          highlight_map[line_num] = "GitStatusModified"
        else -- untracked
          highlight_map[line_num] = "GitStatusUntracked"
        end

        line_num = line_num + 1
      end
    else
      -- Show empty message
      local empty_msg = "  (no files)"
      table.insert(lines, empty_msg)
      highlight_map[line_num] = "GitStatusEmpty"
      line_num = line_num + 1
    end

    table.insert(lines, "")
    line_num = line_num + 1
  end

  return lines, file_map, highlight_map
end

-- Set common buffer options
local function set_buffer_options(bufnr, options)
  for option, value in pairs(options) do
    vim.api.nvim_buf_set_option(bufnr, option, value)
  end
end

-- Create and show a diff buffer
local function create_diff_buffer(file, diff_output)
  local diff_bufnr = vim.api.nvim_create_buf(false, true)
  set_buffer_options(diff_bufnr, {
    buftype = 'nofile',
    filetype = 'diff'
  })
  vim.api.nvim_buf_set_name(diff_bufnr, 'Diff: ' .. file)

  local lines = vim.split(diff_output, '\n')
  vim.api.nvim_buf_set_lines(diff_bufnr, 0, -1, false, lines)
  
  -- Make it non-modifiable after setting content
  set_buffer_options(diff_bufnr, { modifiable = false })

  vim.api.nvim_set_current_buf(diff_bufnr)
end

-- Check if a file is untracked
local function is_file_untracked(file, git_data)
  for _, item in ipairs(git_data.untracked) do
    if item.file == file then
      return true
    end
  end
  return false
end

-- Check if a file is staged
local function is_file_staged(file, git_data)
  for _, item in ipairs(git_data.staged) do
    if item.file == file then
      return true
    end
  end
  return false
end

-- Apply highlighting to the buffer
local function apply_highlighting(bufnr, highlight_map)
  local ns_id = vim.api.nvim_create_namespace("git_status_highlights")
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  for line_num, hl_group in pairs(highlight_map) do
    vim.api.nvim_buf_add_highlight(bufnr, ns_id, hl_group, line_num - 1, 0, -1)
  end
end

-- Set up buffer keymaps for file navigation
local function setup_buffer_keymaps(bufnr, file_map, git_data)
  vim.keymap.set('n', '<CR>', function()
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local file = file_map[line_num]

    if file then
      if is_file_untracked(file, git_data) then
        -- For untracked files, show diff with everything added
        local diff_cmd = "git diff --no-index /dev/null " .. vim.fn.shellescape(file)
        
        -- Get diff output
        local diff_output = run_git_command(diff_cmd)
        -- git diff --no-index exits with 1 when files differ, which is expected
        if vim.v.shell_error ~= 1 and vim.v.shell_error ~= 0 then
          vim.notify("Failed to get diff for " .. file, vim.log.levels.ERROR)
          return
        end

        create_diff_buffer(file, diff_output)
      else
        -- For tracked files, show diff as before
        local absolute_file = get_absolute_path(file)
        local diff_cmd
        if is_file_staged(file, git_data) then
          -- Show diff of staged changes (what will be committed)
          diff_cmd = "git diff --cached " .. vim.fn.shellescape(file)
        else
          -- Check if file exists to determine the right diff command
          local file_exists = vim.fn.filereadable(absolute_file) == 1
          if file_exists then
            -- Show diff of unstaged changes for existing files
            diff_cmd = "git diff " .. vim.fn.shellescape(file)
          else
            -- For deleted files, compare with HEAD
            diff_cmd = "git diff HEAD -- " .. vim.fn.shellescape(file)
          end
        end

        -- Get diff output
        local diff_output = run_git_command(diff_cmd)
        if vim.v.shell_error ~= 0 and diff_output == "" then
          vim.notify("Failed to get diff for " .. file, vim.log.levels.ERROR)
          return
        end

        create_diff_buffer(file, diff_output)
      end
    end
  end, { buffer = bufnr, desc = "Open diff/content for file under cursor" })


  vim.keymap.set('n', 'gd', function()
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local file = file_map[line_num]

    if file then
      local absolute_file = get_absolute_path(file)
      local file_exists = vim.fn.filereadable(absolute_file) == 1
      if file_exists then
        -- Open existing file normally
        vim.cmd('edit ' .. vim.fn.fnameescape(absolute_file))
      else
        -- For deleted files, get content from HEAD and create editable buffer
        local file_content_output = run_git_command("git show HEAD:" .. vim.fn.shellescape(file))
        if vim.v.shell_error ~= 0 then
          vim.notify("Failed to get content for deleted file " .. file, vim.log.levels.ERROR)
          return
        end

        -- Create new buffer for the deleted file
        local new_bufnr = vim.api.nvim_create_buf(false, false)
        vim.api.nvim_buf_set_name(new_bufnr, absolute_file)

        -- Set file content from HEAD
        local lines = vim.split(file_content_output, '\n')
        -- Remove empty last line if present (common with git show)
        if #lines > 0 and lines[#lines] == "" then
          table.remove(lines)
        end
        vim.api.nvim_buf_set_lines(new_bufnr, 0, -1, false, lines)

        -- Set filetype for syntax highlighting and mark as not modified
        local filetype = vim.fn.fnamemodify(file, ":e")
        local options = { modified = false }
        if filetype ~= "" then
          options.filetype = filetype
        end
        set_buffer_options(new_bufnr, options)

        -- Open the buffer
        vim.api.nvim_set_current_buf(new_bufnr)
      end
    end
  end, { buffer = bufnr, desc = "Open file under cursor" })


  vim.keymap.set('n', '<Tab>', function()
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local file = file_map[line_num]

    if file then
      -- Determine which section we're in by checking lines above current position
      local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
      local buffer_lines = vim.api.nvim_buf_get_lines(0, 0, current_line_num, false)
      local in_staged_section = false

      -- Find the most recent section header above current line
      for i = #buffer_lines, 1, -1 do
        local line = buffer_lines[i]
        if line:match("Changes to be committed:") then
          in_staged_section = true
          break
        elseif line:match("Changes not staged for commit:") or line:match("Untracked files:") then
          in_staged_section = false
          break
        end
      end

      -- Perform stage/unstage operation based on section
      local cmd_result
      if in_staged_section then
        -- We're in staged section, so unstage
        local has_commits = run_git_command("git rev-parse --verify HEAD 2>/dev/null")
        if vim.v.shell_error == 0 then
          -- Has commits, can use reset HEAD
          cmd_result = run_git_command("git reset HEAD " .. vim.fn.shellescape(file))
        else
          -- No commits yet, use rm --cached
          cmd_result = run_git_command("git rm --cached " .. vim.fn.shellescape(file))
        end
      else
        -- We're in modified/untracked section, so stage
        -- Check if file is deleted by seeing if it exists
        local absolute_file = get_absolute_path(file)
        local file_exists = vim.fn.filereadable(absolute_file) == 1
        if file_exists then
          cmd_result = run_git_command("git add " .. vim.fn.shellescape(file))
        else
          -- File is deleted, use git rm to stage the deletion
          cmd_result = run_git_command("git rm " .. vim.fn.shellescape(file))
        end
      end

      -- Check for errors
      if vim.v.shell_error ~= 0 then
        vim.notify("Git operation failed: " .. cmd_result, vim.log.levels.ERROR)
        return
      end

      -- Refresh the buffer
      M.refresh_git_status()
    end
  end, { buffer = bufnr, desc = "Stage/unstage file under cursor" })

  vim.keymap.set('n', '<BS>', function()
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local file = file_map[line_num]

    if file then
      if is_file_untracked(file, git_data) then
        -- For untracked files, offer to delete them
        local absolute_file = get_absolute_path(file)
        local confirm = vim.fn.confirm("Delete untracked file " .. file .. "? This cannot be undone.", "&Y\n&n", 1)
        if confirm == 1 then
          local success = vim.fn.delete(absolute_file)
          if success == 0 then
            vim.notify("Deleted " .. file, vim.log.levels.INFO)
            -- Refresh the buffer
            M.refresh_git_status()
          else
            vim.notify("Failed to delete " .. file, vim.log.levels.ERROR)
          end
        end
      else
        -- For tracked files, checkout as before
        local confirm = vim.fn.confirm("Checkout " .. file .. "? This will discard all changes.", "&Y\n&n", 1)
        if confirm == 1 then
          local cmd_result = run_git_command("git checkout -- " .. vim.fn.shellescape(file))

          if vim.v.shell_error ~= 0 then
            vim.notify("Git checkout failed: " .. cmd_result, vim.log.levels.ERROR)
            return
          end

          -- Refresh the buffer
          M.refresh_git_status()
        end
      end
    end
  end, { buffer = bufnr, desc = "Checkout/delete file under cursor" })
end

-- Create and configure git status buffer
local function create_git_status_buffer()
  -- Create a new buffer (listed, not scratch)
  local bufnr = vim.api.nvim_create_buf(false, false)

  -- Set buffer options
  set_buffer_options(bufnr, {
    buftype = 'nofile',
    swapfile = false,
    filetype = 'gitstatus',
    buflisted = true  -- Explicitly make it listed (buftype=nofile makes it unlisted by default)
  })

  -- Set buffer name with unique suffix to avoid conflicts
  local name = 'GitStatus'
  local counter = 1
  while vim.fn.bufexists(name) == 1 do
    name = 'GitStatus-' .. counter
    counter = counter + 1
  end
  vim.api.nvim_buf_set_name(bufnr, name)

  return bufnr
end

-- Refresh git status in current buffer
function M.refresh_git_status()
  if not M._current_buffer or not vim.api.nvim_buf_is_valid(M._current_buffer) then
    return
  end

  local git_data = parse_git_status()
  local content, file_map, highlight_map = format_git_status_content(git_data)

  -- Update buffer content
  set_buffer_options(M._current_buffer, { modifiable = true })
  vim.api.nvim_buf_set_lines(M._current_buffer, 0, -1, false, content)
  set_buffer_options(M._current_buffer, { modifiable = false })

  -- Apply highlighting
  apply_highlighting(M._current_buffer, highlight_map)

  -- Update keymaps with new git_data
  setup_buffer_keymaps(M._current_buffer, file_map, git_data)
end

-- Open git status buffer
function M.open_git_status()
  -- Check if current buffer is already valid and reuse it
  if M._current_buffer and vim.api.nvim_buf_is_valid(M._current_buffer) then
    -- Switch to existing buffer and refresh
    vim.api.nvim_set_current_buf(M._current_buffer)
    M.refresh_git_status()
    return
  else
    -- Clear invalid buffer reference
    M._current_buffer = nil
  end

  -- Check if we're in a git repository
  if not get_git_root() then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end

  -- Setup highlights each time (like regex plugin does)
  setup_highlights()

  local git_data = parse_git_status()
  local content, file_map, highlight_map = format_git_status_content(git_data)

  -- Create buffer
  local bufnr = create_git_status_buffer()
  M._current_buffer = bufnr

  -- Set content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
  set_buffer_options(bufnr, { modifiable = false })

  -- Apply highlighting
  apply_highlighting(bufnr, highlight_map)

  -- Set up keymaps
  setup_buffer_keymaps(bufnr, file_map, git_data)

  -- Set up auto-refresh on buffer enter (skip first time)
  local enter_count = 0
  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = bufnr,
    callback = function()
      enter_count = enter_count + 1
      -- Skip the first BufEnter (when buffer is initially created)
      if enter_count > 1 and M._current_buffer == bufnr then
        M.refresh_git_status()
      end
    end,
  })

  -- Open buffer in current window
  vim.api.nvim_set_current_buf(bufnr)

  -- Set cursor to first file if any
  for line_num, _ in pairs(file_map) do
    vim.api.nvim_win_set_cursor(0, { line_num, 0 })
    break
  end
end

-- Setup
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Commands
  vim.api.nvim_create_user_command("GitStatus", M.open_git_status, {})

  -- Auto-refresh on vim-fugitive operations
  vim.api.nvim_create_autocmd("User", {
    pattern = "FugitiveChanged",
    callback = function()
      M.refresh_git_status()
    end,
  })
end

return M
