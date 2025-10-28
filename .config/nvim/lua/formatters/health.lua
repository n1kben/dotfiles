local M = {}

local function check_formatter_executable(cmd)
  local executable = vim.split(cmd, " ")[1]
  return vim.fn.executable(executable) == 1, executable
end

function M.check()
  local formatters = require("formatters")
  local health = vim.health or require("health")
  
  health.start("Formatters")
  
  local all_formatters = formatters.get_all_formatters()
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
    
    if formatters.has_formatter(ft) then
      local fmt = formatters.get_formatter_info(ft)
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