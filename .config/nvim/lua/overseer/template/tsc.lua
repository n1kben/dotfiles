return {
  name = "tsc",
  builder = function()
    return {
      cmd = { "tsc", "--noEmit" },
      components = {
        { "on_output_parse", problem_matcher = "$tsc" },
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
