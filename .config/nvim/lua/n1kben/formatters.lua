local M = {}

-- Load all formatter files from 'formatter/' folder
local path = vim.fn.stdpath("config") .. "/lua/n1kben/formatters/"
local files = vim.fn.glob(path .. "*.lua", 0, 1) -- list all Lua files

-- Map filetypes to formatter
local formatters = {}
for _, file in ipairs(files) do
  local fmt = dofile(file)
  fmt.name = file:match("([^/]+)%.lua$")
  if fmt.enabled ~= false then
    local fts = type(fmt.filetype) == "table" and fmt.filetype or { fmt.filetype }
    for _, ft in ipairs(fts) do
      if formatters[ft] then
        vim.notify("[Formatter] Duplicate formatter for filetype: " .. ft, vim.log.levels.WARN)
      else
        formatters[ft] = fmt
      end
    end
  end
end

-- Format current buffer in-place
function M.format()
  local ft = vim.bo.filetype
  local fmt = formatters[ft]

  -- Use external formatter if available, otherwise fall back to LSP
  if fmt then
    -- Use external formatter
    local buf = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

    -- Use vim.fn.system for stdin/stdout formatting
    local formatted = vim.fn.system(fmt.cmd, content)

    -- Check for errors
    if vim.v.shell_error ~= 0 then
      vim.notify("[Formatter] Failed: " .. (formatted or "unknown error"), vim.log.levels.ERROR)
      return
    end

    -- Split the formatted content into lines
    local lines = vim.split(formatted, "\n", { plain = true })

    -- Remove trailing empty line if it exists (vim.split often adds one)
    if lines[#lines] == "" then
      table.remove(lines)
    end

    -- Update buffer with formatted content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Restore cursor position (adjust if out of bounds)
    local line_count = vim.api.nvim_buf_line_count(buf)
    if cursor[1] > line_count then
      cursor[1] = line_count
    end
    vim.api.nvim_win_set_cursor(0, cursor)
  else
    -- Fall back to LSP formatting if available
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local formatting_clients = {}

    -- Check for clients that support formatting
    for _, client in ipairs(clients) do
      if client.supports_method("textDocument/formatting") then
        table.insert(formatting_clients, client)
      end
    end

    if #formatting_clients > 0 then
      vim.lsp.buf.format({ async = false })
    end
  end
end

-- Check if formatter exists for current filetype
function M.has_formatter()
  local ft = vim.bo.filetype
  return formatters[ft] ~= nil
end

-- Auto-format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    M.format()
  end,
})

-- Optional: Add a command to manually trigger formatting
vim.api.nvim_create_user_command("Format", function()
  M.format()
end, {})

return M
