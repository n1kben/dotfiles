return {
  "ibhagwan/fzf-lua",
  keys = {
    {
      "<leader>p",
      mode = "n",
      function()
        require("fzf-lua").combine({ pickers = "buffers;oldfiles;files", previewer = false })
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
      "<leader>r",
      mode = "n",
      function()
        require("fzf-lua").lsp_references()
      end,
      { desc = "FZF: LSP references" },
    },
    {
      "<leader>d",
      mode = "n",
      function()
        require("fzf-lua").lsp_document_diagnostics()
      end,
      { desc = "FZF: LSP diagnostics" },
    },
    {
      "<leader>D",
      mode = "n",
      function()
        require("fzf-lua").lsp_workspace_diagnostics()
      end,
      { desc = "FZF: LSP workspace diagnostics" },
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
        require("fzf-lua").grep_project()
      end,
      { desc = "FZF: Fuzzy grep" },
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
      "<leader><CR>",
      mode = "n",
      function()
        require("fzf-lua").resume()
      end,
      { desc = "FZF: Resume" },
    },
    {
      "<leader><BS>",
      mode = "n",
      function()
        require("fzf-lua").resume()
      end,
      { desc = "FZF: Resume" },
    },
    {
      "<leader>u",
      mode = "n",
      function()
        require("n1kben.fzf-undo").pick()
      end,
      { desc = "FZF: Undo tree" },
    },
    {
      "<leader>?",
      mode = "n",
      function()
        require("fzf-lua").builtin()
      end,
      { desc = "FZF: Builtin" },
    },
    {
      "<leader>P",
      mode = "n",
      function()
        require("fzf-lua").builtin()
      end,
      { desc = "FZF: Builtin" },
    }
  },
  config = function()
    local fzf = require("fzf-lua")
    local opts = {
      fzf_colors = true,
      winopts = {
        height = 1,      -- window height
        width = 1,       -- window width
        row = 0,         -- window row position (0=top, 1=bottom)
        col = 0,         -- window col position (0=left, 1=right)
        border = "none", -- window border style
      },
      buffers = {
        actions = false,
        ignore_current_buffer = true,
        fzf_opts = { ["--delimiter"] = fzf.utils.nbsp, ["--with-nth"] = "-1.." },
      },
      oldfiles = {
        cwd_only = true,
      },
      nvim_options = {
        previewer = false,
      },
      keymaps = {
        previewer = false,
      },
      commands = {
        previewer = false,
      },
      blines = {
        previewer = false,
      },
    }
    fzf.setup(opts)

    -- Register fzf-lua as the default vim.ui.select provider
    fzf.register_ui_select()
  end
}
