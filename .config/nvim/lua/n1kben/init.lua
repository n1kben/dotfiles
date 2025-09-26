require("n1kben.keymaps")
require("n1kben.lazy")
require("n1kben.options")
require("n1kben.lsp")
require("n1kben.formatters")
require("n1kben.regex-popup").setup()
require("n1kben.todo")
require("n1kben.alternate").setup({
  dual_patterns = {
    { "*.res",  "*_sandbox.res", "Source File",     "Sandbox File" },
    { "*.res",  "*.bs.mjs",      "ReScript Source", "Compiled JS" },
    { "*.resi", "*.res",         "Interface File",  "Implementation File" },
  }
})
