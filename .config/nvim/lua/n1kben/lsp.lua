-- Options
vim.lsp.inlay_hint.enable()
vim.diagnostic.config({
  virtual_lines = { current_line = true },
})


-- Keymaps
vim.keymap.set("n", "gK", function()
  vim.lsp.buf.hover { border = "rounded" }
end, { desc = "LSP: Hover" })
vim.keymap.set("n", "gd", "<C-]>", { desc = "Go to definition", remap = true })
vim.keymap.set("n", "gD", function()
  vim.diagnostic.open_float({ border = "rounded" })
end, { desc = "Hover diagnostic" })
vim.keymap.set("n", "gra", vim.lsp.buf.code_action, { desc = "LSP: Code action" })
vim.keymap.set("n", "grr", vim.lsp.buf.rename, { desc = "LSP: Rename" })

vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
vim.keymap.set("n", "md", function()
  vim.diagnostic.goto_next({ severity = { min = vim.diagnostic.severity.WARN } })
end, { desc = "Next error/warning" })
vim.keymap.set("n", "Md", function()
  vim.diagnostic.goto_prev({ severity = { min = vim.diagnostic.severity.WARN } })
end, { desc = "Previous error/warning" })
vim.keymap.set("n", "mD", vim.diagnostic.goto_next, { desc = "Next diagnostic (all)" })
vim.keymap.set("n", "MD", vim.diagnostic.goto_prev, { desc = "Previous diagnostic (all)" })

vim.keymap.set("n", "yD", function()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
  if #diagnostics == 0 then
    vim.notify("No diagnostics on current line", vim.log.levels.WARN)
    return
  end
  local messages = {}
  for _, d in ipairs(diagnostics) do
    table.insert(messages, d.message)
  end
  local text = table.concat(messages, "\n")
  vim.fn.setreg("+", text)
  vim.notify("Copied: " .. text:sub(1, 50) .. (text:len() > 50 and "..." or ""), vim.log.levels.INFO)
end, { desc = "Yank diagnostics to clipboard" })


-- LSP client setup
local lsps_to_enable = {}

for _, file in ipairs(vim.fn.glob(vim.fn.stdpath("config") .. "/lsp/*.lua", 0, 1)) do
  local lsp = dofile(file)
  local name = vim.fn.fnamemodify(file, ":t:r")

  if lsp.enabled ~= false then
    table.insert(lsps_to_enable, name)
  end
end

if #lsps_to_enable > 0 then
  vim.lsp.enable(lsps_to_enable)
end

vim.api.nvim_create_user_command("LspRestart", function()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    client:stop()
  end
  vim.defer_fn(function()
    vim.cmd("edit")
  end, 100)
end, { desc = "Restart LSP clients for current buffer" })

-- LSP keybindings that are buffer-local
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach-keybinds', { clear = true }),
  callback = function(ev)
    -- Copy type from LSP hover to clipboard
    local function copy_type()
      local params = vim.lsp.util.make_position_params()
      vim.lsp.buf_request(0, 'textDocument/hover', params, function(err, result)
        if err or not result or not result.contents then
          vim.notify('No type information available', vim.log.levels.WARN)
          return
        end

        -- Extract content from hover result
        local contents = result.contents
        local text
        if type(contents) == 'table' and contents.value then
          text = contents.value
        elseif type(contents) == 'string' then
          text = contents
        elseif type(contents) == 'table' and contents[1] then
          -- Take first item from array
          local item = contents[1]
          text = type(item) == 'string' and item or item.value
        end

        if not text then
          vim.notify('No type information available', vim.log.levels.WARN)
          return
        end

        -- Extract type from markdown code fence if present
        -- Pattern: ```language\ncode\n```
        local type_sig = text:match('```%w*\n(.-)```')
        if type_sig then
          text = vim.trim(type_sig)
        else
          -- Try to extract just first line as fallback
          text = text:match('^([^\n]+)') or text
          text = vim.trim(text)
        end

        -- Copy to system clipboard
        vim.fn.setreg('+', text)
        vim.notify('Copied: ' .. text:sub(1, 50) .. (text:len() > 50 and '...' or ''), vim.log.levels.INFO)
      end)
    end

    vim.keymap.set('n', 'yK', copy_type, { buffer = ev.buf, desc = 'Copy type to clipboard' })
  end,
})
