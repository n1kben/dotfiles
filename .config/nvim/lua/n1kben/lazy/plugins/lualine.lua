return {
  "nvim-lualine/lualine.nvim",
  event = "BufRead",
  config = function()
    local lualine = require("lualine")
    lualine.setup({
      options = {
        theme = "ir-black", -- Custom IR Black lualine theme
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
