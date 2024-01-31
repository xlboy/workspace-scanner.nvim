local flat_handler = require("workspace-scanner.picker.flat_handler")
local tree_handler = require("workspace-scanner.picker.tree_handler")
local history = require("workspace-scanner.picker.history")

local M = {}

local is_initialized = false

--- @param opts WS.Config.Picker
function M.show(opts)
  if not is_initialized then
    history.pin.init(opts)
    history.recent.init(opts)
    is_initialized = true
  end

  if opts.mode == "flat" then
    return flat_handler.show(opts)
  end

  if opts.mode == "tree" then
    return tree_handler.show(opts)
  end
end

return M

-- region     *========= Types =========*

--- @alias WS.Picker.Mode "flat" | "tree"

--- @class WS.Picker.SelectedEntry
--- @field source WS.Scanner.ResultOnlyProject
--- @field is_pinned? boolean
--- @field is_recent? boolean

-- endregion  *========= Types =========*
