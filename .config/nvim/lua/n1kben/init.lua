-- Debug utilities
require("n1kben.debug").setup()

-- Custom confirm modal
require("n1kben.confirm").setup()

require("n1kben.keymaps")
require("n1kben.lazy")
require("n1kben.options")
require("n1kben.lsp")

-- Statusline
require("n1kben.statusline").setup()

-- Last place (restore last cursor position)
require("n1kben.lastplace").setup()

-- Formatter
require("n1kben.formatter").setup({
  auto_format = true,
  notify_on_error = true,
  fallback_to_lsp = true,
})

-- Todo
require("n1kben.todo").setup({})

-- Alternate
require("n1kben.alternate").setup({
  patterns = {
    -- Rescript
    { { "*.res", "Source" },         { "*.bs.mjs", "Compiled" } },
    { { "*.res", "Source" },         { "*_sandbox.res", "Sandbox" } },
    { { "*.res", "Source" },         { "*_test.res", "Test" } },
    { { "*.res", "Implementation" }, { "*.resi", "Interface" } },

    -- TypeScript
    { { "*.tsx", "Source" },         { "*_sandbox.tsx", "Sandbox" } },
    { { "*.ts", "Source" },          { "*_test.ts", "Test" } },
  }
})
