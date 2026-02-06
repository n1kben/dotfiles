return {
  name = "tsc --watch",
  builder = function()
    return {
      cmd = { "tsc", "--noEmit", "--watch" },
      components = {
        { "on_output_parse", problem_matcher = "$tsc-watch" },
        "on_result_diagnostics",
        "default",
      },
    }
  end,
  condition = {
    callback = function(search)
      return vim.fn.filereadable("tsconfig.json") == 1
    end,
  },
}
