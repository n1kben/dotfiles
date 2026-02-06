local M = {}

function M.setup()
  vim.keymap.set("x", "n", function()
    local tmp = vim.fn.getreg("s")
    vim.cmd.normal({ args = { 'gv"sy' }, bang = true })
    vim.fn.setreg("/", "\\V" .. vim.fn.escape(vim.fn.getreg("s"), "/\\"):gsub("\n", "\\n"))
    vim.fn.setreg("s", tmp)
    vim.api.nvim_feedkeys("/" .. vim.fn.getreg("/") .. "\r", "n", false)
  end, { desc = "Search visual selection" })
end

return M
