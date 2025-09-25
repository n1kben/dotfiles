return {
  "rgroli/other.nvim",
  lazy = false,
  config = function()
    local opts = {
      mappings = {
        {
          pattern = "(.*)/(.*).res$",
          {
            {
              target = "**/%2.ts",
              context = "retype-backoffice",
            },
            {
              target = "**/%2.tsx",
              context = "retype-backoffice",
            },
          }
        },
        {
          pattern = "(.*)/(.*).ts(x)?$",
          target = "**/%2.res",
          context = "backoffice",
        }
      }
    }

    require("other-nvim").setup(opts)
  end,
}
