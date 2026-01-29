return {
  cmd = { "rescript-language-server", "--stdio" },
  filetypes = { "rescript" },
  root_markers = { ".rescript.json", ".bsconfig.json" },
  init_options = {
    settings = {
      askToStartBuild = false,
    },
  },
}
