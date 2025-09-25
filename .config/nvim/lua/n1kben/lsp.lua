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
