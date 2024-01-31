local g_utils = require("workspace-scanner.utils")
local config = require("workspace-scanner.config")
local scanner = require("workspace-scanner.scanner")

local M = {}

function M.refresh()
  scanner.cache.refresh()
  g_utils.basic.notify("Cache refreshed", "info")
end

--- @param cfg? WS.Config
function M.setup(cfg)
  config.init(cfg or {})
  scanner.cache.init()
end

--- @param opts? WS.Config.Picker
function M.show_picker(opts)
  opts = vim.tbl_deep_extend("force", config.picker, opts or {})
  if opts.pick_source == nil then
    if scanner.cache.get() == nil then
      g_utils.basic.notify("Cache is empty. Please run `:lua require('workspace-scanner').refresh()`", "error")
      return
    end

    ---@diagnostic disable-next-line: inject-field
    opts.pick_source = scanner.cache.get()
  end

  require("workspace-scanner.picker").show(opts)
end

return M
