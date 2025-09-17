return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "lewis6991/gitsigns.nvim",
  },
  event = "BufRead",
  config = function()
    local lualine = require("lualine")

    local function diff_source()
      local gitsigns = vim.b.gitsigns_status_dict
      if gitsigns then
        return {
          added = gitsigns.added,
          modified = gitsigns.changed,
          removed = gitsigns.removed
        }
      end
    end

    local diagnostics = {
      'diagnostics',
      symbols = { error = '!', warn = '*', info = '?', hint = '?' },
    }

    local filename = {
      'filename',
      file_status = true,    -- Displays file status (readonly status, modified status)
      newfile_status = true, -- Display new file status (new file means no write after created)
      path = 1,
      -- 0: Just the filename
      -- 1: Relative path
      -- 2: Absolute path
      -- 3: Absolute path, with tilde as the home directory
      -- 4: Filename and parent dir, with tilde as the home directory

      shorting_target = 40, -- Shortens path to leave 40 spaces in the window
      -- for other components. (terrible name, any suggestions?)
      symbols = {
        modified = '[+]',      -- Text to show when the file is modified.
        readonly = '[-]',      -- Text to show when the file is non-modifiable or readonly.
        unnamed = '[No Name]', -- Text to show for unnamed buffers.
        newfile = '[New]',     -- Text to show for newly created file before first write
      }
    }

    lualine.setup({
      options = {
        theme = "auto",
        globalstatus = true,
        section_separators = "",
        component_separators = "",
        disabled_filetypes = { "mason", "lazy", "NvimTree", "oil" },
      },
      sections = {
        lualine_a = {},
        lualine_b = { filename },
        lualine_c = {},
        lualine_x = {},
        lualine_y = { diagnostics, "location", { 'diff', source = diff_source } },
        lualine_z = { { 'b:gitsigns_head', icon = '' } },
      },
    })
  end,
}
