return {
  {
    "claude-autocomplete",
    enabled = false,
    dir = vim.fn.expand("~/.config/nvim/lua/claude-autocomplete"),
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("claude-autocomplete").setup({
        keymaps = {
          accept_suggestion = "<Tab>",
          accept_word = "<S-Tab>",
          clear_suggestion = "<C-]>",
        },
        example_rescript_file =
        "/Users/viktor/Developer/carlaviktor/web/feature/apps/backoffice/src/components/logistic/show/LogisticShowHeader.res", -- e.g., "/path/to/example.res"
        example_typescript_file =
        "/Users/viktor/Developer/carlaviktor/web/feature/apps/retype-backoffice/src/logistics/LogisticEventShowHeader.tsx",    -- e.g., "/path/to/example.ts"
        debounce_ms = 1500,
      })
    end,
  },
}
