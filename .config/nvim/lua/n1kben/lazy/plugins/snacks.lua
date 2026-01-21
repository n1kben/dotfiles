return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    input = { enabled = true },
    notifier = { enabled = true },
    styles = {
      notification_history = {
        border = "rounded",
        zindex = 100,
        width = 0.9,
        height = 0.9,
        minimal = true,
        title = " Notification History ",
        title_pos = "center",
        ft = "markdown",
        bo = { filetype = "snacks_notif_history", modifiable = false },
        wo = { winhighlight = "Normal:SnacksNotifierHistory" },
        keys = { q = "close" },
      }
    },
  },
}
