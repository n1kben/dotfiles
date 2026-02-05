local M = {}

-- Setup
function M.setup()
  local ignore_filetypes = { "gitcommit", "gitrebase", "commit" }

  vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
      if vim.bo.buftype ~= "" then return end

      local ft = vim.bo.filetype
      for _, ignored in ipairs(ignore_filetypes) do
        if ft == ignored then return end
      end

      local mark = vim.api.nvim_buf_get_mark(0, '"')
      local lcount = vim.api.nvim_buf_line_count(0)
      if mark[1] > 0 and mark[1] <= lcount then
        pcall(vim.api.nvim_win_set_cursor, 0, mark)
      end
    end,
  })
end

return M
