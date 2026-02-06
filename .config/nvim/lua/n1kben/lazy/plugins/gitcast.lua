return {
  -- Use local development version
  dir = vim.fn.expand("~/Developer/n1kben/vimplugins/gitcast"),
  name = "gitcast.nvim",
  cmd = "GitCast",
  keys = {
    { "<leader>g", desc = "GitCast" },
  },
  config = function()
    require("gitcast").setup({
      performance_tracking = false, -- Enable to see what's slow
    })
  end,
}
