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
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "lsp_status", "diagnostics", "filetype", "location" },
        lualine_y = {},
        lualine_z = {},
      },
    })
  end,
}
