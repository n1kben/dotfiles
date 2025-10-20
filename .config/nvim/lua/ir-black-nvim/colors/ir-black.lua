-- IR Black colorscheme for Neovim
-- Based on the original IR Black theme by Todd Werth
-- Ported to modern Neovim with Lua

local M = {}

-- Color palette from the original IR Black
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

-- Highlight groups
local function set_highlights()
  local highlights = {
    -- Editor highlights
    Normal = { fg = colors.normal_text, bg = colors.black },
    NormalFloat = { fg = colors.normal_text, bg = colors.black },
    NormalNC = { fg = colors.normal_text, bg = colors.black },

    -- Cursor
    Cursor = { fg = colors.black, bg = colors.cursor_under },
    CursorLine = { bg = colors.current_line },
    CursorColumn = { bg = colors.current_line },

    -- Line numbers
    LineNr = { fg = colors.line_numbers },
    CursorLineNr = { fg = colors.normal_text, bg = colors.current_line },

    -- Visual selection
    Visual = { bg = colors.visual_selection },
    VisualNOS = { bg = colors.visual_selection },

    -- Search
    Search = { bg = colors.search_selection },
    IncSearch = { bg = colors.search_selection },

    -- Syntax highlighting
    Comment = { fg = colors.comments, italic = true },

    -- Constants
    Constant = { fg = colors.numbers },
    String = { fg = colors.strings },
    Character = { fg = colors.strings },
    Number = { fg = colors.numbers },
    Boolean = { fg = colors.numbers },
    Float = { fg = colors.numbers },

    -- Identifiers
    Identifier = { fg = colors.methods },
    Function = { fg = colors.classes },

    -- Statements
    Statement = { fg = colors.keywords },
    Conditional = { fg = colors.keywords },
    Repeat = { fg = colors.keywords },
    Label = { fg = colors.keywords },
    Operator = { fg = colors.normal_text },
    Keyword = { fg = colors.keywords },
    Exception = { fg = colors.keywords },

    -- PreProcessor
    PreProc = { fg = colors.red },
    Include = { fg = colors.red },
    Define = { fg = colors.red },
    Macro = { fg = colors.red },
    PreCondit = { fg = colors.red },

    -- Types
    Type = { fg = colors.classes },
    StorageClass = { fg = colors.keywords },
    Structure = { fg = colors.keywords },
    Typedef = { fg = colors.keywords },

    -- Special
    Special = { fg = colors.regex },
    SpecialChar = { fg = colors.regex },
    Tag = { fg = colors.regex },
    Delimiter = { fg = colors.normal_text },
    SpecialComment = { fg = colors.regex },
    Debug = { fg = colors.regex },

    -- Underlined
    Underlined = { underline = true },

    -- Ignore
    Ignore = { fg = colors.comments },

    -- Error
    Error = { fg = colors.red, bg = colors.black },
    ErrorMsg = { fg = colors.red },
    WarningMsg = { fg = colors.cursor_under },

    -- Todo
    Todo = { fg = colors.classes, bg = colors.black, bold = true },

    -- UI elements
    StatusLine = { fg = colors.light_gray, bg = colors.dark_gray },
    StatusLineNC = { fg = colors.comments, bg = colors.black },
    VertSplit = { fg = colors.line_numbers },
    WinSeparator = { fg = colors.line_numbers },

    -- Popup menu
    Pmenu = { fg = colors.normal_text, bg = colors.dark_gray },
    PmenuSel = { fg = colors.black, bg = colors.keywords },
    PmenuSbar = { bg = colors.line_numbers },
    PmenuThumb = { bg = colors.normal_text },

    -- Folding
    Folded = { fg = colors.comments, bg = colors.current_line },
    FoldColumn = { fg = colors.line_numbers, bg = colors.black },

    -- Diff
    DiffAdd = { fg = colors.strings },
    DiffChange = { fg = colors.regex },
    DiffDelete = { fg = colors.red },
    DiffText = { fg = colors.normal_text, bg = colors.current_line },

    -- Spell
    SpellBad = { undercurl = true, sp = colors.red },
    SpellCap = { undercurl = true, sp = colors.cursor_under },
    SpellLocal = { undercurl = true, sp = colors.regex },
    SpellRare = { undercurl = true, sp = colors.light_purple },

    -- Directory
    Directory = { fg = colors.keywords },

    -- Title
    Title = { fg = colors.classes, bold = true },

    -- Matching parentheses
    MatchParen = { fg = colors.normal_text, bg = colors.visual_selection },

    -- Non-text
    NonText = { fg = colors.line_numbers },
    SpecialKey = { fg = colors.line_numbers },

    -- Tabs
    TabLine = { fg = colors.comments, bg = colors.black },
    TabLineFill = { bg = colors.black },
    TabLineSel = { fg = colors.normal_text, bg = colors.current_line },

    -- Wild menu
    WildMenu = { fg = colors.black, bg = colors.keywords },

    -- Git signs (for gitsigns.nvim) - Enhanced
    GitSignsAdd = { fg = colors.strings },
    GitSignsChange = { fg = colors.regex },
    GitSignsDelete = { fg = colors.red },
    GitSignsAddNr = { fg = colors.strings },
    GitSignsChangeNr = { fg = colors.regex },
    GitSignsDeleteNr = { fg = colors.red },
    GitSignsAddLn = { bg = colors.current_line },
    GitSignsChangeLn = { bg = colors.current_line },
    GitSignsDeleteLn = { bg = colors.current_line },
    GitSignsCurrentLineBlame = { fg = colors.comments, italic = true },

    -- FZF-lua comprehensive theming
    FzfLuaNormal = { fg = colors.normal_text, bg = colors.black },
    FzfLuaBorder = { fg = colors.line_numbers, bg = colors.black },
    FzfLuaTitle = { fg = colors.classes, bg = colors.black, bold = true },
    FzfLuaPreviewNormal = { fg = colors.normal_text, bg = colors.black },
    FzfLuaPreviewBorder = { fg = colors.line_numbers, bg = colors.black },
    FzfLuaPreviewTitle = { fg = colors.classes, bg = colors.black, bold = true },
    FzfLuaCursor = { fg = colors.black, bg = colors.cursor_under },
    FzfLuaCursorLine = { bg = colors.current_line },
    FzfLuaSearch = { fg = colors.keywords, bg = colors.search_selection },
    FzfLuaScrollBorderEmpty = { fg = colors.line_numbers },
    FzfLuaScrollBorderFull = { fg = colors.keywords },
    FzfLuaScrollFloatEmpty = { fg = colors.line_numbers },
    FzfLuaScrollFloatFull = { fg = colors.keywords },
    FzfLuaTabTitle = { fg = colors.classes, bold = true },
    FzfLuaTabMarker = { fg = colors.red },
    FzfLuaHeaderBind = { fg = colors.keywords },
    FzfLuaHeaderText = { fg = colors.normal_text },
    FzfLuaPathColNr = { fg = colors.line_numbers },
    FzfLuaPathLineNr = { fg = colors.line_numbers },
    FzfLuaBufName = { fg = colors.classes },
    FzfLuaBufNr = { fg = colors.numbers },
    FzfLuaBufLineNr = { fg = colors.line_numbers },
    FzfLuaBufFlagCur = { fg = colors.keywords },
    FzfLuaBufFlagAlt = { fg = colors.regex },
    FzfLuaLiveSym = { fg = colors.keywords },
    FzfLuaFzfMatch = { fg = colors.keywords, bold = true },
    FzfLuaFzfBorder = { fg = colors.line_numbers },
    FzfLuaFzfScrollbar = { fg = colors.keywords },
    FzfLuaFzfSeparator = { fg = colors.line_numbers },
    FzfLuaFzfGutter = { bg = colors.black },
    FzfLuaFzfHeader = { fg = colors.normal_text },
    FzfLuaFzfInfo = { fg = colors.comments },
    FzfLuaFzfPointer = { fg = colors.red },
    FzfLuaFzfMarker = { fg = colors.strings },
    FzfLuaFzfSpinner = { fg = colors.regex },
    FzfLuaFzfPrompt = { fg = colors.keywords },
    FzfLuaFzfQuery = { fg = colors.normal_text },

    -- Oil.nvim file manager theming
    OilNormal = { fg = colors.normal_text, bg = colors.black },
    OilDir = { fg = colors.keywords, bold = true },
    OilFile = { fg = colors.normal_text },
    OilLink = { fg = colors.strings },
    OilCopy = { fg = colors.regex },
    OilMove = { fg = colors.cursor_under },
    OilChange = { fg = colors.regex },
    OilCreate = { fg = colors.strings },
    OilDelete = { fg = colors.red },
    OilPermissionNone = { fg = colors.comments },
    OilPermissionRead = { fg = colors.keywords },
    OilPermissionWrite = { fg = colors.regex },
    OilPermissionExecute = { fg = colors.strings },
    OilTypeDir = { fg = colors.keywords },
    OilTypeFile = { fg = colors.normal_text },
    OilTypeLink = { fg = colors.strings },
    OilTypeSocket = { fg = colors.light_purple },
    OilTypeFifo = { fg = colors.brown },

    -- Mason.nvim package manager theming
    MasonNormal = { fg = colors.normal_text, bg = colors.black },
    MasonHeader = { fg = colors.classes, bg = colors.black, bold = true },
    MasonHeaderSecondary = { fg = colors.keywords, bg = colors.black, bold = true },
    MasonHighlight = { fg = colors.keywords },
    MasonHighlightBlock = { fg = colors.black, bg = colors.keywords },
    MasonHighlightBlockBold = { fg = colors.black, bg = colors.keywords, bold = true },
    MasonHighlightSecondary = { fg = colors.regex },
    MasonHighlightBlockSecondary = { fg = colors.black, bg = colors.regex },
    MasonHighlightBlockBoldSecondary = { fg = colors.black, bg = colors.regex, bold = true },
    MasonMuted = { fg = colors.comments },
    MasonMutedBlock = { fg = colors.comments, bg = colors.current_line },
    MasonMutedBlockBold = { fg = colors.comments, bg = colors.current_line, bold = true },
    MasonError = { fg = colors.red },
    MasonWarning = { fg = colors.cursor_under },
    MasonHeading = { fg = colors.classes, bold = true },
    MasonLink = { fg = colors.strings, underline = true },

    -- Tree-sitter highlights
    ["@comment"] = { fg = colors.comments, italic = true },
    ["@string"] = { fg = colors.strings },
    ["@number"] = { fg = colors.numbers },
    ["@boolean"] = { fg = colors.numbers },
    ["@keyword"] = { fg = colors.keywords },
    ["@function"] = { fg = colors.classes },
    ["@type"] = { fg = colors.classes },
    ["@variable"] = { fg = colors.normal_text },
    ["@constant"] = { fg = colors.numbers },
    ["@operator"] = { fg = colors.normal_text },
    ["@punctuation"] = { fg = colors.normal_text },
    ["@tag"] = { fg = colors.keywords },
    ["@attribute"] = { fg = colors.methods },

    -- Tree-sitter diff highlights
    ["@diff.plus"] = { bg = "#1a2e1a" },  -- Added lines (subtle dark green)
    ["@diff.minus"] = { bg = "#2e1a1a" }, -- Deleted lines (subtle dark red)
    ["@diff.delta"] = { bg = "#2e2a1a" }, -- Changed lines (subtle dark brown)

    -- LSP
    DiagnosticError = { fg = colors.red },
    DiagnosticWarn = { fg = colors.cursor_under },
    DiagnosticInfo = { fg = colors.keywords },
    DiagnosticHint = { fg = colors.comments },

    -- Completion
    CmpItemAbbrMatch = { fg = colors.keywords, bold = true },
    CmpItemAbbrMatchFuzzy = { fg = colors.keywords, bold = true },
    CmpItemKind = { fg = colors.methods },
    CmpItemMenu = { fg = colors.comments },
  }

  -- Apply highlights
  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

function M.setup()
  -- Clear existing highlights
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  -- Set color scheme name
  vim.g.colors_name = "ir-black"

  -- Set background
  vim.o.background = "dark"

  -- Apply highlights
  set_highlights()
end

return M
