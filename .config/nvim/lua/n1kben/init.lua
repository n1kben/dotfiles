-- Debug utilities
require("n1kben.debug").setup()

-- Custom confirm modal
require("n1kben.confirm").setup()

require("n1kben.keymaps")
require("n1kben.lazy")
require("n1kben.options")
require("n1kben.lsp")

-- GitCast is now loaded as a plugin via lazy.nvim (see plugins/gitcast.lua)

-- Last place (restore last cursor position)
require("n1kben.lastplace").setup()

-- Regex tester
require("n1kben.regex-popup").setup()

-- Todo
require("n1kben.todo").setup({})

-- Highlight utilities
require("n1kben.highlights").setup()

-- Alternate
require("n1kben.alternate").setup({
  patterns = {
    -- Rescript
    { { "*.res", "Source" },         { "*.bs.mjs", "Compiled" } },
    { { "*.res", "Source" },         { "*_sandbox.res", "Sandbox " } },
    { { "*.res", "Source" },         { "*_test.res", "Test " } },
    { { "*.res", "Implementation" }, { "*.resi", "Interface" } },

    -- TypeScript
    { { "*.tsx", "Source" },         { "*_sandbox.tsx", "Sandbox " } },
    { { "*.ts", "Source" },          { "*_test.ts", "Test " } },
  }
})
