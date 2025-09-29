require("n1kben.keymaps")
require("n1kben.lazy")
require("n1kben.options")
require("n1kben.lsp")
require("n1kben.formatters")
require("n1kben.regex-popup").setup()

-- Todo
require("n1kben.todo").setup({})

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
