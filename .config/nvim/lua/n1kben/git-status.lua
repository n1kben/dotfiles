-- lua/git-status.lua
local M = {}

-- Default configuration
M.config = {}

-- Setup highlight groups for git status
local function setup_highlights()
  -- Section headers - white
  vim.api.nvim_set_hl(0, "GitStatusHeader", { fg = "#FFFFFF" }) -- White

  -- File statuses - better colors
  vim.api.nvim_set_hl(0, "GitStatusStaged", { fg = "#98C379" })    -- Nice green (changes to be committed)
  vim.api.nvim_set_hl(0, "GitStatusModified", { fg = "#E06C75" })  -- Nice red (not staged for commit)
  vim.api.nvim_set_hl(0, "GitStatusUntracked", { fg = "#E06C75" }) -- Nice red (untracked files)

  -- Instructions and empty messages - gray
  vim.api.nvim_set_hl(0, "GitStatusInstructions", { fg = "#808080" }) -- Gray
  vim.api.nvim_set_hl(0, "GitStatusEmpty", { fg = "#808080" })        -- Gray

  -- Branch info - cyan
  vim.api.nvim_set_hl(0, "GitStatusBranch", { fg = "#56B6C2" }) -- Cyan
end

-- Git status sections with their display names
local SECTIONS = {
  { key = "staged",    name = "Changes to be committed:" },
  { key = "modified",  name = "Changes not staged for commit:" },
  { key = "untracked", name = "Untracked files:" },
}

-- Synchronous version for backwards compatibility
local function parse_git_status()
  local result = { staged = {}, modified = {}, untracked = {} }

  -- Get staged files
  local staged_output = vim.fn.system("git diff --name-status --cached")
  if vim.v.shell_error == 0 and staged_output ~= "" then
    for line in staged_output:gmatch("[^\r\n]+") do
      local status, file = line:match("^(%S+)%s+(.+)$")
      if status and file then
        table.insert(result.staged, { status = status, file = file })
      end
    end
  end

  -- Get modified files
  local modified_output = vim.fn.system("git diff --name-status")
  if vim.v.shell_error == 0 and modified_output ~= "" then
    for line in modified_output:gmatch("[^\r\n]+") do
      local status, file = line:match("^(%S+)%s+(.+)$")
      if status and file then
        table.insert(result.modified, { status = status, file = file })
      end
    end
  end

  -- Get untracked files
  local untracked_output = vim.fn.system("git ls-files --others --exclude-standard")
  if vim.v.shell_error == 0 and untracked_output ~= "" then
    for file in untracked_output:gmatch("[^\r\n]+") do
      if file ~= "" then
        table.insert(result.untracked, { status = "??", file = file })
      end
    end
  end

  return result
end

-- Format git status display content
local function format_git_status_content(git_data)
  local lines = {}
  local file_map = {}      -- Map line numbers to files
  local highlight_map = {} -- Map line numbers to highlight groups
  local line_num = 1

  -- Get current branch
  local branch_output = vim.fn.system("git branch --show-current 2>/dev/null")
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
  table.insert(lines, "Press <CR> for diff, gd to open file, <Tab> to stage/unstage, gk to commit")
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
        local display_line = string.format("  %s %s", item.status, item.file)
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
      -- Check if file is staged or modified to determine diff command
      local is_staged = false
      for _, item in ipairs(git_data.staged) do
        if item.file == file then
          is_staged = true
          break
        end
      end

      local diff_cmd
      if is_staged then
        -- Show diff of staged changes (what will be committed)
        diff_cmd = "git diff --cached " .. vim.fn.shellescape(file)
      else
        -- Show diff of unstaged changes
        diff_cmd = "git diff " .. vim.fn.shellescape(file)
      end

      -- Get diff output
      local diff_output = vim.fn.system(diff_cmd)
      if vim.v.shell_error ~= 0 then
        vim.notify("Failed to get diff for " .. file, vim.log.levels.ERROR)
        return
      end

      -- Create diff buffer
      local diff_bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(diff_bufnr, 'buftype', 'nofile')
      vim.api.nvim_buf_set_option(diff_bufnr, 'filetype', 'diff')
      vim.api.nvim_buf_set_name(diff_bufnr, 'Diff: ' .. file)

      -- Set diff content
      local lines = vim.split(diff_output, '\n')
      vim.api.nvim_buf_set_lines(diff_bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(diff_bufnr, 'modifiable', false)

      -- Open diff buffer
      vim.api.nvim_set_current_buf(diff_bufnr)
    end
  end, { buffer = bufnr, desc = "Open diff for file under cursor" })


  vim.keymap.set('n', 'gd', function()
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local file = file_map[line_num]

    if file then
      -- Open the file in a new buffer
      vim.cmd('edit ' .. vim.fn.fnameescape(file))
    end
  end, { buffer = bufnr, desc = "Open file under cursor" })

  vim.keymap.set('n', 'gk', function()
    -- Use callback version of vim.ui.input
    vim.ui.input({ prompt = "Commit message: " }, function(commit_msg)
      if commit_msg and commit_msg ~= "" then
        -- Run git commit with the message
        local result = vim.fn.system("git commit -m " .. vim.fn.shellescape(commit_msg))
        if vim.v.shell_error == 0 then
          vim.notify("Committed successfully", vim.log.levels.INFO)
          -- Refresh the git status buffer after a short delay
          vim.defer_fn(function()
            M.refresh_git_status()
          end, 100)
        else
          vim.notify("Commit failed: " .. result, vim.log.levels.ERROR)
        end
      end
    end)
  end, {
    buffer = bufnr,
    desc = "Commit with message",
    noremap = true, -- Don't allow remapping
    silent = true   -- Don't show in command line
  })

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
        local has_commits = vim.fn.system("git rev-parse --verify HEAD 2>/dev/null")
        if vim.v.shell_error == 0 then
          -- Has commits, can use reset HEAD
          cmd_result = vim.fn.system("git reset HEAD " .. vim.fn.shellescape(file))
        else
          -- No commits yet, use rm --cached
          cmd_result = vim.fn.system("git rm --cached " .. vim.fn.shellescape(file))
        end
      else
        -- We're in modified/untracked section, so stage
        cmd_result = vim.fn.system("git add " .. vim.fn.shellescape(file))
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
end

-- Create and configure git status buffer
local function create_git_status_buffer()
  -- Create a new buffer (listed, not scratch)
  local bufnr = vim.api.nvim_create_buf(false, false)

  -- Set buffer options
  vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(bufnr, 'swapfile', false)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'gitstatus')
  -- Explicitly make it listed (buftype=nofile makes it unlisted by default)
  vim.api.nvim_buf_set_option(bufnr, 'buflisted', true)

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
  if not M._current_buffer then
    return
  end

  local git_data = parse_git_status()
  local content, file_map, highlight_map = format_git_status_content(git_data)

  -- Update buffer content
  vim.api.nvim_buf_set_option(M._current_buffer, 'modifiable', true)
  vim.api.nvim_buf_set_lines(M._current_buffer, 0, -1, false, content)
  vim.api.nvim_buf_set_option(M._current_buffer, 'modifiable', false)

  -- Apply highlighting
  apply_highlighting(M._current_buffer, highlight_map)

  -- Update keymaps with new git_data
  setup_buffer_keymaps(M._current_buffer, file_map, git_data)
end

-- Open git status buffer
function M.open_git_status()
  -- Check if current buffer is already valid and reuse it
  if M._current_buffer then
    -- Switch to existing buffer and refresh
    vim.api.nvim_set_current_buf(M._current_buffer)
    return
  end

  -- Check if we're in a git repository
  local _ = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error ~= 0 then
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
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)

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
end

return M
