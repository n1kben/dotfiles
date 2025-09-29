return {
  "nvim-lualine/lualine.nvim",
  event = "BufRead",
  config = function()
    local lualine = require("lualine")
    local colors = {
      black        = '#000000',
      white        = '#ffffff',
      red          = '#fb4934',
      green        = '#b8bb26',
      blue         = '#83a598',
      yellow       = '#fe8019',
      gray         = '#a89984',
      darkgray     = '#3c3836',
      lightgray    = '#B5B3A9',
      inactivegray = '#504945',
    }
    local a = { bg = colors.black, fg = colors.lightgray }
    local b = a
    local c = b
    local theme = {
      normal = { a = a, b = b, c = c },
      insert = { a = a, b = b, c = c },
      visual = { a = a, b = b, c = c },
      replace = { a = a, b = b, c = c },
      command = { a = a, b = b, c = c },
      inactive = { a = a, b = b, c = c },
    }

    lualine.setup({
      options = {
        theme = theme,
        padding = { left = 0, right = 0 },
        section_separators = "",
        component_separators = "",
        disabled_filetypes = { "mason", "lazy", "NvimTree", "oil" },
      },
      sections = {
        lualine_a = {},
        lualine_b = { "filename", "location" },
        lualine_c = {},
        lualine_x = {},
        lualine_y = {
          "diagnostics",
          { "branch", icon = "" },
          { 'diff',   padding = { left = 1 } },
        },
        lualine_z = {},
      },
    })
  end,
}
