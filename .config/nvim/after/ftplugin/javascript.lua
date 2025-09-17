vim.opt_local.expandtab = true
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2

-- Go to alternate file aka .bs.mjs file with same name as current file
-- if current file is the bs.mjs switch to .res file and if in .res switch to bs.mjs
vim.keymap.set('n', 'ga', function()
  local current_file = vim.api.nvim_buf_get_name(0)
  local bs_ext = ".bs.mjs"
  local res_ext = ".res"

  if current_file:sub(- #bs_ext) == bs_ext then
    -- Replace .bs.mjs with .res
    local target_file = current_file:sub(1, - #bs_ext - 1) .. res_ext
    vim.cmd("edit " .. target_file)
  elseif current_file:sub(- #res_ext) == res_ext then
    -- Replace .res with .bs.mjs
    local target_file = current_file:sub(1, - #res_ext - 1) .. bs_ext
    vim.cmd("edit " .. target_file)
  else
    print("Not a .bs.mjs or .res file")
  end
end, { buffer = true })
