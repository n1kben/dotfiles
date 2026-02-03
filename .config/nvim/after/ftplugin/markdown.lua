vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.conceallevel = 0
vim.opt_local.concealcursor = "ncv"
vim.opt_local.expandtab = true
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2

vim.g["surround_" .. string.byte("*")] = "**\r**"
vim.g["surround_" .. string.byte("_")] = "_"
vim.g["surround_" .. string.byte("-")] = "~\r~"

local function get_relative_date(date_str)
  local year, month, day = date_str:match("(%d%d%d%d)-(%d%d)-(%d%d)")
  if not year then return nil end

  local input_time = os.time({ year = year, month = month, day = day, hour = 12 })
  local today = os.time({ year = os.date("%Y"), month = os.date("%m"), day = os.date("%d"), hour = 12 })
  local diff_days = math.floor((input_time - today) / (24 * 60 * 60))

  if diff_days == 0 then
    return "today"
  elseif diff_days == 1 then
    return "tomorrow"
  elseif diff_days == -1 then
    return "yesterday"
  elseif diff_days > 1 then
    return "in " .. diff_days .. " days"
  else
    return math.abs(diff_days) .. " days ago"
  end
end

local function update_date_labels()
  local ns = vim.api.nvim_create_namespace("date_labels")
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

  for line_nr, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local col = 1
    while true do
      local start_pos, end_pos = line:find("%d%d%d%d%-%d%d%-%d%d", col)
      if not start_pos then break end

      local date_str = line:sub(start_pos, end_pos)
      local relative_date = get_relative_date(date_str)
      if relative_date then
        vim.api.nvim_buf_set_extmark(0, ns, line_nr - 1, end_pos, {
          virt_text = { { " (" .. relative_date .. ")", "Comment" } },
          virt_text_pos = "inline",
        })
      end

      col = end_pos + 1
    end
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "InsertLeave" }, {
  buffer = 0,
  callback = update_date_labels,
})

update_date_labels()
