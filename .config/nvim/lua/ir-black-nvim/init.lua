-- IR Black theme plugin for Neovim
-- Main plugin file

local M = {}

function M.setup(opts)
  opts = opts or {}
  
  -- Load the colorscheme
  require("ir-black-nvim.colors.ir-black").setup()
end

-- Function to load the colorscheme
function M.load()
  require("ir-black-nvim.colors.ir-black").setup()
end

return M