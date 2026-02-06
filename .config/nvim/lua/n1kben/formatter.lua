local M = {}

local formatters_cache = {}
local config = {
  auto_format = true,
  notify_on_error = true,
  fallback_to_lsp = true,
}

local function load_formatters()
  if next(formatters_cache) then
    return formatters_cache
  end

  local path = vim.fn.stdpath("config") .. "/lua/formatters/"
  local files = vim.fn.glob(path .. "*.lua", 0, 1)

  for _, file in ipairs(files) do
    local ok, fmt = pcall(dofile, file)
    if ok then
      fmt.name = file:match("([^/]+)%.lua$")
      if fmt.enabled ~= false then
        local fts = type(fmt.filetype) == "table" and fmt.filetype or { fmt.filetype }
        for _, ft in ipairs(fts) do
          if formatters_cache[ft] then
            if config.notify_on_error then
              vim.notify("[Formatter] Duplicate formatter for filetype: " .. ft, vim.log.levels.WARN)
            end
          else
            formatters_cache[ft] = fmt
          end
        end
      end
    else
      if config.notify_on_error then
        vim.notify("[Formatter] Failed to load: " .. file, vim.log.levels.ERROR)
      end
    end
  end

  return formatters_cache
end

function M.format(opts)
  opts = opts or {}
  local ft = opts.filetype or vim.bo.filetype
  local formatters = load_formatters()
  local fmt = formatters[ft]

  if fmt then
    local buf = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

    -- Build the command, replacing placeholders
    local cmd = fmt.cmd
    local filename = vim.api.nvim_buf_get_name(buf)
    -- Escape the filename for shell use
    local escaped_filename = vim.fn.shellescape(filename)
    cmd = cmd:gsub("${filename}", escaped_filename)
    cmd = cmd:gsub("${filetype}", ft)

    local formatted = vim.fn.system(cmd, content)

    if vim.v.shell_error ~= 0 then
      if config.notify_on_error then
        vim.notify("[Formatter] Failed: " .. (formatted or "unknown error"), vim.log.levels.ERROR)
      end
      return false
    end

    local lines = vim.split(formatted, "\n", { plain = true })

    if lines[#lines] == "" then
      table.remove(lines)
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local line_count = vim.api.nvim_buf_line_count(buf)
    if cursor[1] > line_count then
      cursor[1] = line_count
    end
    vim.api.nvim_win_set_cursor(0, cursor)
    return true
  elseif config.fallback_to_lsp then
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local formatting_clients = {}

    for _, client in ipairs(clients) do
      if client.supports_method("textDocument/formatting") then
        table.insert(formatting_clients, client)
      end
    end

    if #formatting_clients > 0 then
      vim.lsp.buf.format({ async = false })
      return true
    end
  end

  return false
end

function M.has_formatter(ft)
  ft = ft or vim.bo.filetype
  local formatters = load_formatters()
  return formatters[ft] ~= nil
end

function M.get_formatter_info(ft)
  ft = ft or vim.bo.filetype
  local formatters = load_formatters()
  return formatters[ft]
end

function M.get_all_formatters()
  return load_formatters()
end

function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_deep_extend("force", config, opts)

  if config.auto_format then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("FormattersAutoFormat", { clear = true }),
      pattern = "*",
      callback = function()
        M.format()
      end,
    })
  end

  vim.api.nvim_create_user_command("Format", function(args)
    M.format({ filetype = args.args ~= "" and args.args or nil })
  end, {
    nargs = "?",
    complete = function()
      return vim.tbl_keys(load_formatters())
    end,
  })

  vim.api.nvim_create_user_command("FormatInfo", function()
    local ft = vim.bo.filetype
    local fmt = M.get_formatter_info(ft)
    if fmt then
      vim.print({
        filetype = ft,
        formatter = fmt.name,
        command = fmt.cmd
      })
    else
      vim.notify("No formatter configured for filetype: " .. ft, vim.log.levels.INFO)
    end
  end, {})
end

local function check_formatter_executable(cmd)
  local executable = vim.split(cmd, " ")[1]
  return vim.fn.executable(executable) == 1, executable
end

function M.check_health()
  local health = vim.health

  health.start("Formatters")

  local all_formatters = M.get_all_formatters()
  local formatter_count = vim.tbl_count(all_formatters)

  if formatter_count == 0 then
    health.warn("No formatters configured")
    return
  end

  health.info(string.format("Found %d formatter configuration(s)", formatter_count))

  local available_formatters = {}
  local missing_formatters = {}
  local filetype_formatters = {}

  for ft, fmt in pairs(all_formatters) do
    filetype_formatters[fmt.name] = filetype_formatters[fmt.name] or {}
    table.insert(filetype_formatters[fmt.name], ft)

    local is_available, executable = check_formatter_executable(fmt.cmd)
    if is_available then
      available_formatters[fmt.name] = true
    else
      missing_formatters[fmt.name] = executable
    end
  end

  health.start("Formatter executables")

  for name, _ in pairs(available_formatters) do
    local fts = table.concat(filetype_formatters[name], ", ")
    health.ok(string.format("%s: available for [%s]", name, fts))
  end

  for name, executable in pairs(missing_formatters) do
    if not available_formatters[name] then
      local fts = table.concat(filetype_formatters[name], ", ")
      health.warn(string.format("%s: '%s' not found in PATH for [%s]", name, executable, fts))

      if executable == "prettier" then
        health.info("  Install with: npm install -g prettier")
      elseif executable == "shfmt" then
        health.info("  Install with: brew install shfmt (macOS) or check https://github.com/mvdan/sh")
      end
    end
  end

  health.start("Current buffer")

  local ft = vim.bo.filetype
  if ft == "" then
    health.info("No filetype detected")
  else
    health.info(string.format("Filetype: %s", ft))

    if M.has_formatter(ft) then
      local fmt = M.get_formatter_info(ft)
      local is_available, executable = check_formatter_executable(fmt.cmd)
      if is_available then
        health.ok(string.format("Formatter configured: %s (%s)", fmt.name, fmt.cmd))
      else
        health.error(string.format("Formatter configured but not available: %s (%s not found)", fmt.name, executable))
      end
    else
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      local has_lsp_formatter = false

      for _, client in ipairs(clients) do
        if client.supports_method("textDocument/formatting") then
          has_lsp_formatter = true
          health.info(string.format("LSP formatter available: %s", client.name))
        end
      end

      if not has_lsp_formatter then
        health.info("No formatter configured for this filetype")
      end
    end
  end

  health.start("Configuration")

  local has_autoformat = vim.api.nvim_get_autocmds({
    group = "FormattersAutoFormat",
    event = "BufWritePre"
  })

  if #has_autoformat > 0 then
    health.ok("Auto-format on save: enabled")
  else
    health.info("Auto-format on save: disabled")
  end

  if vim.fn.exists(":Format") == 2 then
    health.ok("Format command: available")
  else
    health.warn("Format command: not available")
  end

  if vim.fn.exists(":FormatInfo") == 2 then
    health.ok("FormatInfo command: available")
  else
    health.info("FormatInfo command: not available")
  end
end

return M
