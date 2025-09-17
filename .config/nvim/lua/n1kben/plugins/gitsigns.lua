return {
  "lewis6991/gitsigns.nvim",
  event = "BufRead",
  opts = {
    on_attach = function(bufnr)
      local gitsigns = require("gitsigns")

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gitsigns.nav_hunk("next")
        end
      end)
      map("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gitsigns.nav_hunk("prev")
        end
      end)

      -- Normal
      map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "Git Signs: Stage Hunk" })
      map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "Git Signs: Reset Hunk" })
      map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "Git Signs: Stage Buffer" })
      map("n", "<leader>hu", gitsigns.undo_stage_hunk, { desc = "Git Signs: Undo Stage Hunk" })
      map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "Git Signs: Reset Buffer" })
      map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "Git Signs: Preview Hunk" })

      -- Visual
      map("v", "<leader>hs", function() gitsigns.stage_hunk { vim.fn.line("."), vim.fn.line("v") } end,
        { desc = "Git Signs: Stage Hunk" })
      map("v", "<leader>hr", function() gitsigns.reset_hunk { vim.fn.line("."), vim.fn.line("v") } end,
        { desc = "Git Signs: Reset Hunk" })

      -- Text object
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Git Signs: Select Hunk" })
    end
  },
}
