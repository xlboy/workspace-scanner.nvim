local data_dir = vim.fn.stdpath("data") .. "/workspace-scanner"

--- @class WS.Config
local _default_config = {
  scanner = {
    source = {},
    cache_path = data_dir .. "/scan-result-cache.json",
    patterns = { "README.md", ".git", ".hg", ".svn", ".project", ".root", "package.json" },
  },
  --- @class WS.Config.Picker
  picker = {
    mode = "flat", --- @type WS.Picker.Mode
    flat_opts = {
      --- If true, includes tree history (pin/recent)
      include_tree_history = true,
      separator = " > ",
    },
    tree_opts = {
      --- If true, includes flat history (pin/recent)
      include_flat_history = true,
      workspace = {
        icon = "📁", --- @type string | false
        history_recent = {
          enabled = true,
          --- @type boolean
          --- If true, adopts the latest data from all its project nodes
          derive_from_children = true,
          icon = "🕒", --- @type string | false
        },
      },
      keymaps = {
        back = "<C-h>",
        forward = "<C-l>",
      },
    },
    --- @type nil | WS.Scanner.Result[]
    --- If nil, use scanner cache
    pick_source = nil,
    --- If true, show only history
    show_history_only = false,
    history = {
      recent = {
        enabled = true,
        cache_path = data_dir .. "/picker-recent-history.json",
        keymaps = { delete = "<C-d>" },
        icon = "🕒", --- @type string | false
      },
      pin = {
        enabled = true,
        cache_path = data_dir .. "/picker-pin-history.json",
        keymaps = { toggle = "<C-g>" },
        icon = "📌", --- @type string | false
      },
    },
    telescope = {
      --- Telescope configuration: https://github.com/nvim-telescope/telescope.nvim/blob/master/doc/telescope.txt#L87
      opts = {
        layout_config = { height = 25, width = 110 },
      },
    },
    events = {
      --- Hook executed after selecting elements in Picker
      --- @param entry WS.Picker.SelectedEntry
      on_select = function(entry)
        vim.cmd("cd " .. entry.source.dir)
      end,
    },
  },
}

local _config = _default_config

--- @type WS.Config
local M = {}

--- @param config WS.Config
---@diagnostic disable-next-line: inject-field
M.init = function(config)
  _config = vim.tbl_deep_extend("force", _default_config, config)
end

return setmetatable(M, {
  __index = function(_, key)
    return _config[key]
  end,
})
