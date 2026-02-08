local function has_ts_parser()
  local ok, parser = pcall(vim.treesitter.get_parser)
  return ok and parser ~= nil
end

return {
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  keys = {
    {
      "gj",
      function()
        if has_ts_parser() then
          require("treesj").join()
        else
          vim.cmd("normal! J")
        end
      end,
      desc = "Join lines",
    },
    {
      "gK",
      function()
        if has_ts_parser() then
          require("treesj").split()
        else
          vim.cmd([[execute "normal! i\<CR>"]])
        end
      end,
      desc = "Split lines",
    },
  },
  opts = {
    use_default_keymaps = false,
  },
}
