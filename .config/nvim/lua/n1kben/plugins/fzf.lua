return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  keys = {
    {
      "<leader>p",
      mode = "n",
      function()
        require("fzf-lua").combine({ pickers = "buffers;files", previewer = false })
      end,
      { desc = "FZF: MRU files" },
    },
    {
      "<leader>o",
      mode = "n",
      function()
        require("fzf-lua").lsp_document_symbols()
      end,
      { desc = "FZF: LSP document symbols" },
    },
    {
      "<leader>O",
      mode = "n",
      function()
        require("fzf-lua").lsp_workspace_symbols()
      end,
      { desc = "FZF: LSP workspace symbols" },
    },
    {
      "<leader>f",
      mode = "n",
      function()
        require("fzf-lua").blines()
      end,
      { desc = "FZF: Lines" },
    },
    {
      "<leader>F",
      mode = "n",
      function()
        require("fzf-lua").live_grep()
      end,
      { desc = "FZF: Live grep" },
    },
    {
      "<leader>N",
      mode = "n",
      function()
        require("fzf-lua").grep_cword()
      end,
      { desc = "FZF: Grep word under cursor" },
    },
    {
      "<leader>N",
      mode = "v",
      function()
        require("fzf-lua").grep_visual()
      end,
      { desc = "FZF: Grep visual selection" },
    },
    {
      "<leader>P",
      mode = { "n", "v" },
      function()
        require("fzf-lua").keymaps()
      end,
      { desc = "FZF: Keymaps" },
    },
    {
      "<leader><CR>",
      mode = "n",
      function()
        require("fzf-lua").resume()
      end,
      { desc = "FZF: Resume" },
    },
  },
  config = function()
    local fzf = require("fzf-lua")
    local opts = {
      fzf_colors = true,
      -- winopts = {
      --   height = 1,      -- window height
      --   width = 1,       -- window width
      --   row = 0,         -- window row position (0=top, 1=bottom)
      --   col = 0,         -- window col position (0=left, 1=right)
      --   border = "none", -- window border style
      -- },
      buffers = {
        actions = false,
        ignore_current_buffer = true,
        fzf_opts = { ["--delimiter"] = fzf.utils.nbsp, ["--with-nth"] = "-1.." },
      },
      keymaps = {
        previewer = false,
      },
      -- lsp = {
      --   symbols = {
      --     previewer = false,
      --   },
      --   workspaceSymbols = {
      --     previewer = false,
      --   },
      -- },
      commands = {
        previewer = false,
      },
      blines = {
        previewer = false,
      },
    }
    fzf.setup(opts)
  end
}
