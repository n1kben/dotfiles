local function in_list(val, list)
  for _, v in ipairs(list) do
    if v == val then return true end
  end
  return false
end

return {
  "stevearc/oil.nvim",
  lazy = false,
  keys = {
    { "-", "<cmd>Oil<cr>", { desc = "Open parent directory" } },
  },
  opts = {
    use_default_keymaps = false,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    prompt_save_on_select_new_entry = false,
    view_options = {
      is_hidden_file = function(name, _)
        return name:sub(1, 1) == "."
      end,
      is_always_hidden = function(name, _)
        return name == ".." or name == ".DS_Store"
      end,
    },
    keymaps = {
      ["<leader>."] = "actions.toggle_hidden",
      ["<CR>"] = function()
        local oil = require("oil")
        local entry = oil.get_cursor_entry()
        local dir = oil.get_current_dir()
        if not entry or not dir then
          return
        end
        local external_exts = { "png", "jpg", "jpeg", "gif", "mov", "pdf" }
        local ext = entry.name:match("%.([^.]+)$")
        ext = ext and ext:lower()
        if ext and in_list(ext, external_exts) then
          local path = dir .. entry.name
          if vim.ui.open then
            vim.ui.open(path)
            return
          else
            vim.notify(string.format("Could not open %s", path), vim.log.levels.ERROR)
          end
        else
          oil.select({}, nil)
        end
      end,
      ["R"] = "actions.refresh",
      ["-"] = "actions.parent",
      ["_"] = "actions.open_cwd",
      ["~"] = { "actions.cd", opts = { scope = "tab" }, desc = ":tcd to the current oil directory" },
      ["?"] = "actions.preview",
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "oil_preview",
      callback = function(params)
        vim.keymap.set("n", "<CR>", "y", { buffer = params.buf, remap = true, nowait = true })
      end,
    })
  end,
}
