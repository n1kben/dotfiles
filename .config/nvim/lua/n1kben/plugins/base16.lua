return {
  "RRethy/base16-nvim",
  lazy = false,
  init = function()
    vim.api.nvim_create_autocmd("OptionSet", {
      pattern = "background",
      callback = function()
        if vim.o.background == "dark" then
          vim.cmd.colorscheme("base16-irblack")
        else
          require('base16-colorscheme').setup({
            -- Background / UI
            base00 = '#ffffff', -- Default Background
            base01 = '#f6f7f9', -- Lighter Background (status bars, line numbers)
            base02 = '#e6e9ee', -- Selection Background
            base03 = '#6b7280', -- Comments, Invisibles, Line Highlight
            base04 = '#4b5563', -- Dark Foreground (Status bar text)
            base05 = '#0b1220', -- Default Foreground, Caret, Delimiters, Operators
            base06 = '#374151', -- Light Foreground (Not often used)
            base07 = '#111827', -- Light Background (cursorline, etc.)

            -- Accents
            base08 = '#ef4444', -- Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
            base09 = '#f59e0b', -- Integers, Boolean, Constants
            base0A = '#d97706', -- Classes, Markup Bold, Search Text Background
            base0B = '#10b981', -- Strings, Inherited Class, Markup Code, Diff Inserted
            base0C = '#0598bd', -- Support, Regular Expressions, Escape Characters
            base0D = '#0f62fe', -- Functions, Methods, Diff Changed
            base0E = '#7c3aed', -- Keywords, Storage, Selector, Markup Italic, Diff Changed
            base0F = '#a16207', -- Deprecated, Embedded Language Tags
          })
        end
      end,
    })
  end,
}
