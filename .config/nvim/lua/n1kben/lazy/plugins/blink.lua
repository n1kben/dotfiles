return {
  'saghen/blink.cmp',
  event = { "InsertEnter", "CmdlineEnter" },
  opts = {
    fuzzy = { implementation = "lua" },
    cmdline = {
      keymap = { preset = 'inherit' },
      completion = { menu = { auto_show = true } },
    },
  },
  opts_extend = { "sources.default" }
}
