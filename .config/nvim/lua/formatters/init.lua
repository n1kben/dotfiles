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

  local path = vim.fn.stdpath("config") .. "/lua/formatters/formatters/"
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
    cmd = cmd:gsub("${filename}", filename)
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

return M

