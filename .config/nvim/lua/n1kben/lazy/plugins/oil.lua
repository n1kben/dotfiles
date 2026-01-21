return {
  "stevearc/oil.nvim",
  lazy = false,
  keys = {
    { "-", "<cmd>Oil<cr>", { desc = "Oil: Open current directory" } },
  },
  config = function()
    local oil = require("oil")

    -- helper function to parse output
    local function parse_output(proc)
      local result = proc:wait()
      local ret = {}
      if result.code == 0 then
        for line in vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true }) do
          -- Remove trailing slash
          line = line:gsub("/$", "")
          ret[line] = true
        end
      end
      return ret
    end

    -- build git status cache
    local function new_git_status()
      return setmetatable({}, {
        __index = function(self, key)
          local ignore_proc = vim.system(
            { "git", "ls-files", "--ignored", "--exclude-standard", "--others", "--directory" },
            {
              cwd = key,
              text = true,
            }
          )
          local tracked_proc = vim.system({ "git", "ls-tree", "HEAD", "--name-only" }, {
            cwd = key,
            text = true,
          })
          local ret = {
            ignored = parse_output(ignore_proc),
            tracked = parse_output(tracked_proc),
          }

          rawset(self, key, ret)
          return ret
        end,
      })
    end
    local git_status = new_git_status()

    -- Clear git status cache on refresh
    local refresh = require("oil.actions").refresh
    local orig_refresh = refresh.callback
    refresh.callback = function(...)
      git_status = new_git_status()
      orig_refresh(...)
    end


    local opts = {
      columns = {},
      use_default_keymaps = false,
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      prompt_save_on_select_new_entry = false,
      view_options = {
        is_hidden_file = function(name, bufnr)
          local dir = require("oil").get_current_dir(bufnr)
          local is_dotfile = vim.startswith(name, ".") and name ~= ".."
          -- if no local directory (e.g. for ssh connections), just hide dotfiles
          if not dir then
            return is_dotfile
          end
          -- dotfiles are considered hidden unless tracked
          if is_dotfile then
            return not git_status[dir].tracked[name]
          else
            -- Check if file is gitignored
            return git_status[dir].ignored[name]
          end
        end,
        is_always_hidden = function(name, _)
          return name == ".." or name == ".DS_Store"
        end,
      },
      keymaps = {
        ["g."] = "actions.toggle_hidden",
        ["<CR>"] = "actions.select",
        ["<S-CR>"] = "actions.open_external",
        ["+"] = function()
          require("oil").set_columns({ "permissions" })
        end,
        ["R"] = "actions.refresh",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["~"] = "actions.cd",
        ["?"] = "actions.preview",
      },
    }
    oil.setup(opts)

    -- remap <CR> to accept changes (instead of using y and n)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "oil_preview",
      callback = function(params)
        vim.keymap.set("n", "<CR>", "y", { buffer = params.buf, remap = true, nowait = true })
      end,
    })
  end,
}
