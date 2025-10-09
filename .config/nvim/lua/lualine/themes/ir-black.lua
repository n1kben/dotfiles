-- Lualine theme for IR Black colorscheme
-- Based on the original IR Black vim theme by Todd Werth

local colors = {
  -- Main colors
  black = "#000000",
  white = "#FFFFFF",

  -- Text colors
  normal_text = "#f6f3e8",
  comments = "#7C7C7C",

  -- Syntax colors
  strings = "#A8FF60",
  string_inner = "#00A0A0",
  numbers = "#FF73FD",
  keywords = "#96CBFE",
  classes = "#FFFFB6",
  methods = "#FFD2A7",
  regex = "#E9C062",

  -- Interface colors
  cursor_under = "#FFA560",
  visual_selection = "#1D1E2C",
  current_line = "#151515",
  search_selection = "#07281C",
  line_numbers = "#3D3D3D",

  -- Additional colors
  red = "#FF6C60",
  light_red = "#FFB6B0",
  brown = "#E18964",
  light_purple = "#FFCCFF",

  -- Grays
  dark_gray = "#262626",
  medium_gray = "#808080",
  light_gray = "#CCCCCC",
}

local ir_black = {}

ir_black.normal = {
  a = { fg = colors.black, bg = colors.keywords, gui = 'bold' },
  b = { fg = colors.normal_text, bg = colors.current_line },
  c = { fg = colors.comments, bg = colors.black },
  x = { fg = colors.comments, bg = colors.black },
  y = { fg = colors.normal_text, bg = colors.current_line },
  z = { fg = colors.black, bg = colors.keywords, gui = 'bold' },
}

ir_black.insert = {
  a = { fg = colors.black, bg = colors.strings, gui = 'bold' },
  b = { fg = colors.normal_text, bg = colors.current_line },
  c = { fg = colors.comments, bg = colors.black },
  x = { fg = colors.comments, bg = colors.black },
  y = { fg = colors.normal_text, bg = colors.current_line },
  z = { fg = colors.black, bg = colors.strings, gui = 'bold' },
}

ir_black.visual = {
  a = { fg = colors.black, bg = colors.regex, gui = 'bold' },
  b = { fg = colors.normal_text, bg = colors.current_line },
  c = { fg = colors.comments, bg = colors.black },
  x = { fg = colors.comments, bg = colors.black },
  y = { fg = colors.normal_text, bg = colors.current_line },
  z = { fg = colors.black, bg = colors.regex, gui = 'bold' },
}

ir_black.replace = {
  a = { fg = colors.black, bg = colors.red, gui = 'bold' },
  b = { fg = colors.normal_text, bg = colors.current_line },
  c = { fg = colors.comments, bg = colors.black },
  x = { fg = colors.comments, bg = colors.black },
  y = { fg = colors.normal_text, bg = colors.current_line },
  z = { fg = colors.black, bg = colors.red, gui = 'bold' },
}

ir_black.command = {
  a = { fg = colors.black, bg = colors.light_purple, gui = 'bold' },
  b = { fg = colors.normal_text, bg = colors.current_line },
  c = { fg = colors.comments, bg = colors.black },
  x = { fg = colors.comments, bg = colors.black },
  y = { fg = colors.normal_text, bg = colors.current_line },
  z = { fg = colors.black, bg = colors.light_purple, gui = 'bold' },
}

ir_black.inactive = {
  a = { fg = colors.comments, bg = colors.black },
  b = { fg = colors.comments, bg = colors.black },
  c = { fg = colors.comments, bg = colors.black },
  x = { fg = colors.comments, bg = colors.black },
  y = { fg = colors.comments, bg = colors.black },
  z = { fg = colors.comments, bg = colors.black },
}

-- Terminal mode
ir_black.terminal = ir_black.insert

return ir_black

