local M = {}

M.config = {
  path_style = 'relative', -- 'relative' (to cwd), 'absolute', or 'git_root'
}

local function get_git_root()
  local result = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  if result.code ~= 0 or not result.stdout then return nil end
  return vim.trim(result.stdout)
end

local function get_git_remote_url()
  local result = vim.system({ 'git', 'remote', 'get-url', 'origin' }, { text = true }):wait()
  if result.code ~= 0 or not result.stdout then return nil end
  return vim.trim(result.stdout)
end

local function parse_github_url(remote_url)
  -- SSH: git@github.com:org/repo.git (also handles aliases like github.com-user)
  local org, repo = remote_url:match('^git@github%.com[^:]*:([^/]+)/(.+)')
  if not org then
    -- HTTPS: https://github.com/org/repo.git
    org, repo = remote_url:match('^https://github%.com/([^/]+)/(.+)')
  end
  if not org then return nil, nil end
  repo = repo:gsub('%.git$', '')
  return org, repo
end

local function get_git_commit()
  local result = vim.system({ 'git', 'rev-parse', 'HEAD' }, { text = true }):wait()
  if result.code ~= 0 or not result.stdout then return nil end
  return vim.trim(result.stdout)
end

local function get_file_path()
  local abs_path = vim.fn.expand('%:p')
  local style = M.config.path_style

  if style == 'absolute' then
    return abs_path
  elseif style == 'git_root' then
    local git_root = get_git_root()
    if git_root then
      return abs_path:sub(#git_root + 2)
    end
    return vim.fn.fnamemodify(abs_path, ':.')
  else
    return vim.fn.fnamemodify(abs_path, ':.')
  end
end

--
-- Copy file location to clipboard
--
function M.location(is_visual)
  local path = get_file_path()
  local location

  if is_visual then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local start_line, start_col = start_pos[2], start_pos[3]
    local end_line, end_col = end_pos[2], end_pos[3]

    -- In visual line mode, end_col is maxcol (v:maxcol); clamp to actual line length
    if end_col >= 2147483647 then
      end_col = #vim.fn.getline(end_line)
    end

    location = string.format('%s:%d:%d-%d:%d', path, start_line, start_col, end_line, end_col)
  else
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1]
    local col = cursor[2] + 1 -- convert 0-based to 1-based
    location = string.format('%s:%d:%d', path, line, col)
  end

  vim.fn.setreg('+', location)
  vim.notify('Copied: ' .. location, vim.log.levels.INFO, { title = "Copy - Location" })
end

--
-- Copy type from LSP hover to clipboard
--
function M.lsp_type()
  local client = vim.lsp.get_clients({ bufnr = 0 })[1]
  if not client then
    vim.notify('No LSP client attached', vim.log.levels.WARN, { title = "Copy - LSP Type" })
    return
  end
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  vim.lsp.buf_request(0, 'textDocument/hover', params, function(err, result)
    if err or not result or not result.contents then
      vim.notify('No type information available', vim.log.levels.WARN, { title = "Copy - LSP Type" })
      return
    end

    local contents = result.contents
    local text
    if type(contents) == 'table' and contents.value then
      text = contents.value
    elseif type(contents) == 'string' then
      text = contents
    elseif type(contents) == 'table' and contents[1] then
      local item = contents[1]
      text = type(item) == 'string' and item or item.value
    end

    if not text then
      vim.notify('No type information available', vim.log.levels.WARN, { title = "Copy - LSP Type" })
      return
    end

    local type_sig = text:match('```%w*\n(.-)```')
    if type_sig then
      text = vim.trim(type_sig)
    else
      text = vim.trim(text)
    end

    vim.fn.setreg('+', text)
    vim.notify('Copied: ' .. text:sub(1, 50) .. (text:len() > 50 and '...' or ''), vim.log.levels.INFO, { title = "Copy - LSP Type" })
  end)
end

--
-- Copy LSP diagnostic message to clipboard
--
function M.lsp_diagnostic()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_line = cursor[1] - 1 -- 0-based
  local cursor_col = cursor[2]

  local diagnostics = vim.diagnostic.get(0, { lnum = cursor_line })
  if #diagnostics == 0 then
    vim.notify('No diagnostics on current line', vim.log.levels.WARN, { title = "Copy - LSP Diagnostic" })
    return
  end

  local best = diagnostics[1]
  local best_dist = math.abs(best.col - cursor_col)
  for i = 2, #diagnostics do
    local dist = math.abs(diagnostics[i].col - cursor_col)
    if dist < best_dist then
      best = diagnostics[i]
      best_dist = dist
    end
  end

  local msg = best.message
  vim.fn.setreg('+', msg)
  vim.notify('Copied: ' .. msg:sub(1, 50) .. (msg:len() > 50 and '...' or ''), vim.log.levels.INFO, { title = "Copy - LSP Diagnostic" })
end

--
-- Copy location with LSP hover context to clipboard
--
function M.location_context()
  local client = vim.lsp.get_clients({ bufnr = 0 })[1]
  if not client then
    return M.location(false)
  end

  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  vim.lsp.buf_request(0, 'textDocument/hover', params, function(err, result)
    if err or not result or not result.contents then
      return M.location(false)
    end

    local contents = result.contents
    local text
    if type(contents) == 'table' and contents.value then
      text = contents.value
    elseif type(contents) == 'string' then
      text = contents
    elseif type(contents) == 'table' and contents[1] then
      local item = contents[1]
      text = type(item) == 'string' and item or item.value
    end

    if not text then
      return M.location(false)
    end

    local inner = text:match('```%w*\n(.-)```')
    if inner then
      text = vim.trim(inner)
    else
      text = vim.trim(text)
    end

    local kind = text:match('^%((%w+)%)')
        or text:match('^(%w+)%s')

    local cword = vim.fn.expand('<cword>')
    local path = get_file_path()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1]
    local col = cursor[2] + 1

    local location
    if kind then
      location = string.format('%s `%s` in %s:%d:%d', kind, cword, path, line, col)
    else
      location = string.format('`%s` in %s:%d:%d', cword, path, line, col)
    end

    vim.fn.setreg('+', location)
    vim.notify('Copied: ' .. location, vim.log.levels.INFO, { title = "Copy - Location Context" })
  end)
end

--
-- Copy GitHub URL for current location to clipboard
--
function M.location_github(is_visual)
  local git_root = get_git_root()
  if not git_root then
    vim.notify('Not in a git repository', vim.log.levels.WARN, { title = "Copy - GitHub URL" })
    return
  end

  local remote_url = get_git_remote_url()
  if not remote_url then
    vim.notify('No git remote origin found', vim.log.levels.WARN, { title = "Copy - GitHub URL" })
    return
  end

  local org, repo = parse_github_url(remote_url)
  if not org then
    vim.notify('Remote is not a GitHub URL', vim.log.levels.WARN, { title = "Copy - GitHub URL" })
    return
  end

  local commit = get_git_commit()
  if not commit then
    vim.notify('Could not determine git commit', vim.log.levels.WARN, { title = "Copy - GitHub URL" })
    return
  end

  -- Capture buffer state before async call
  local rel_path = vim.fn.expand('%:p'):sub(#git_root + 2)
  local line_ref

  if is_visual then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
    local start_line = vim.fn.getpos("'<")[2]
    local end_line = vim.fn.getpos("'>")[2]
    line_ref = string.format('#L%d-L%d', start_line, end_line)
  else
    local line = vim.api.nvim_win_get_cursor(0)[1]
    line_ref = string.format('#L%d', line)
  end

  -- Check if file has uncommitted changes
  local diff_result = vim.system({ 'git', 'diff', '--quiet', 'HEAD', '--', rel_path }, { cwd = git_root }):wait()
  if diff_result.code ~= 0 then
    vim.notify('File has uncommitted changes', vim.log.levels.WARN, { title = 'Copy - GitHub URL' })
    return
  end

  -- Check if commit has been pushed to remote (async to avoid blocking)
  vim.system({ 'git', 'branch', '-r', '--contains', commit }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 or not result.stdout or vim.trim(result.stdout) == '' then
        vim.notify('Current commit has not been pushed to remote', vim.log.levels.WARN, { title = 'Copy - GitHub URL' })
        return
      end

      local url = string.format('https://github.com/%s/%s/blob/%s/%s%s', org, repo, commit, rel_path, line_ref)
      vim.fn.setreg('+', url)
      vim.notify('Copied: ' .. url, vim.log.levels.INFO, { title = 'Copy - GitHub URL' })
    end)
  end)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  vim.keymap.set('n', 'yl', function() M.location(false) end, { desc = 'Copy file location' })
  vim.keymap.set('x', 'yl', function() M.location(true) end, { desc = 'Copy file location (visual)' })
  vim.keymap.set('n', 'yL', function() M.location_github(false) end, { desc = 'Copy GitHub URL' })
  vim.keymap.set('x', 'yL', function() M.location_github(true) end, { desc = 'Copy GitHub URL (visual)' })
end

return M
