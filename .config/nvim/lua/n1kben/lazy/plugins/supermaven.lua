return {
  "supermaven-inc/supermaven-nvim",
  enabled = true,
  event = "InsertEnter",
  opts = {
    keymaps = {
      accept_suggestion = "<S-Tab>",
      accept_word = "<Tab>",
    },
  },
}
