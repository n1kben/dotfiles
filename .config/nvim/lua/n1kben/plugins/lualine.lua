return {
  "nvim-lualine/lualine.nvim",
  event = "BufRead",
  config = function()
    local lualine = require("lualine")
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
        lualine_b = { "filename" },
        lualine_c = {},
        lualine_x = {},
        lualine_y = { "diagnostics", "filetype", "location" },
        lualine_z = {},
      },
    })
  end,
}
