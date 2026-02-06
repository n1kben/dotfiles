local M = {}

function M.setup()
  local branch_name = ""
  local branch_icon = " "

  local function update_branch()
    local b = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
    branch_name = b
  end

  update_branch()

  vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained" }, {
    callback = update_branch,
  })

  vim.api.nvim_set_hl(0, "StatusBranch", { link = "Function" })

  vim.o.statusline = "%!v:lua.Statusline()"

  local function short_path(path)
    local home = vim.env.HOME
    if home and path:sub(1, #home) == home then
      path = "~" .. path:sub(#home + 1)
    end
    return path
  end

  function Statusline()
    local name = vim.api.nvim_buf_get_name(0)
    local path, mod
    if name:find("^oil://") then
      path = short_path(name:sub(7))
      mod = ""
    elseif name ~= "" then
      path = short_path(name)
      mod = " %m"
    else
      path = "[No Name]"
      mod = " %m"
    end

    local br = ""
    if branch_name ~= "" then
      local win_w = vim.api.nvim_win_get_width(0)
      local path_w = vim.fn.strdisplaywidth(path)
      local icon_w = vim.fn.strdisplaywidth(branch_icon)
      -- estimate fixed parts: spaces, %m, %l:%c, separators
      local avail = win_w - path_w - icon_w - 15
      local bname = branch_name
      local min_len = math.min(10, #bname)
      if avail < #bname then
        local len = math.max(min_len, avail)
        bname = bname:sub(1, len)
        if len < #branch_name then
          bname = bname .. "…"
        end
      end
      br = "%#StatusBranch#" .. branch_icon .. bname .. "%*"
    end

    return " %<" .. path .. mod .. " %= " .. br .. "  %l:%c "
  end
end

return M
