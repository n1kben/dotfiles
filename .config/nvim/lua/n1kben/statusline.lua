local M = {}

function M.setup()
  local branch = ""

  local function update_branch()
    local b = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
    branch = b ~= "" and " " .. b or ""
  end

  update_branch()

  vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained" }, {
    callback = update_branch,
  })

  vim.o.statusline = "%!v:lua.Statusline()"

  function Statusline()
    return " %f %m %= " .. branch .. "  %l:%c "
  end
end

return M
