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
