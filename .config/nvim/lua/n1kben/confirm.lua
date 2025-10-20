-- Simple vim.ui.confirm replacement with snacks styling
local M = {}

local defaults = {
  icon = "󰻂 ",
}

-- Set up highlight groups
local function setup_highlights()
  vim.api.nvim_set_hl(0, "ConfirmNormal", { link = "Normal", default = true })
  vim.api.nvim_set_hl(0, "ConfirmBorder", { link = "DiagnosticInfo", default = true })
  vim.api.nvim_set_hl(0, "ConfirmTitle", { link = "DiagnosticInfo", default = true })
  vim.api.nvim_set_hl(0, "ConfirmHint", { link = "Comment", default = true })
end

local ui_confirm = vim.ui.confirm

---@param opts? {msg?: string, icon?: string}
---@param on_confirm fun(confirmed: boolean)
function M.confirm(opts, on_confirm)
  assert(type(on_confirm) == "function", "`on_confirm` must be a function")
  
  setup_highlights()
  opts = vim.tbl_extend("force", defaults, opts or {})
  opts.msg = opts.msg or "Confirm?"
  
  local parent_win = vim.api.nvim_get_current_win()
  local mode = vim.fn.mode()
  
  local function close_and_confirm(result)
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(parent_win) then
        vim.api.nvim_set_current_win(parent_win)
        if mode == "i" then
          vim.cmd("startinsert")
        end
      end
      on_confirm(result)
    end)
  end
  
  -- Create buffer and content
  local buf = vim.api.nvim_create_buf(false, true)
  local msg_lines = vim.split(opts.msg, '\n', { plain = true })
  local footer = "󰄬 Enter to confirm    󰅖 Esc to cancel"
  local content = vim.list_extend(vim.deepcopy(msg_lines), { "", footer })
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  
  -- Calculate dimensions
  local max_width = vim.api.nvim_strwidth(footer)
  for _, line in ipairs(msg_lines) do
    max_width = math.max(max_width, vim.api.nvim_strwidth(line))
  end
  
  local width = math.min(math.max(40, max_width + 6), math.floor(vim.o.columns * 0.8))
  local height = math.min(#content, math.floor(vim.o.lines * 0.6))
  local col = math.floor((vim.o.columns - width) / 2)
  local row = 2  -- Top positioning like snacks input
  
  -- Create window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    border = "rounded",
    style = "minimal",
    title = { { " " .. opts.icon .. "Confirm ", "ConfirmTitle" } },
  })
  
  -- Configure buffer and window
  vim.bo[buf].filetype = "confirm"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  
  vim.wo[win].winhighlight = "NormalFloat:ConfirmNormal,FloatBorder:ConfirmBorder,FloatTitle:ConfirmTitle"
  vim.wo[win].wrap = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].cursorline = false
  vim.wo[win].cursorcolumn = false
  
  -- Highlight footer
  local ns = vim.api.nvim_create_namespace("confirm_highlight")
  vim.api.nvim_buf_add_highlight(buf, ns, "ConfirmHint", #msg_lines + 1, 0, -1)
  
  -- Position cursor at the checkmark in footer to make it look intentional
  local footer_line = #msg_lines + 2  -- +1 for empty line, +1 for footer (1-indexed)
  local checkmark_pos = 0  -- Position of the checkmark icon
  vim.api.nvim_win_set_cursor(win, { footer_line, checkmark_pos })
  
  vim.keymap.set("n", "<CR>", function() 
    close_and_confirm(true)
    vim.api.nvim_win_close(win, true) 
  end, { buffer = buf, silent = true })
  
  vim.keymap.set("n", "<Esc>", function() 
    close_and_confirm(false)
    vim.api.nvim_win_close(win, true) 
  end, { buffer = buf, silent = true })
  
  -- Auto-close on window leave
  vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
    buffer = buf,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        close_and_confirm(false)
        vim.api.nvim_win_close(win, true)
      end
    end,
  })
  
  return { win = win, buf = buf }
end

function M.setup()
  vim.ui.confirm = M.confirm
end

return M