local g_utils = require("workspace-scanner.utils")

local M = {}

--- @param w_dir string
--- @return string[] -- sub directories(absolute path)
M.get_sub_dirs = function(w_dir)
  local dirs = {}
  w_dir = g_utils.path.append_slash(w_dir)
  for _, dir in ipairs(vim.fn.glob(w_dir .. "*/", true, true)) do
    if vim.fn.isdirectory(dir) == 1 then
      table.insert(dirs, g_utils.path.unify_slash(dir))
    end
  end
  return dirs
end

M.get_dir_name = function(dir)
  return vim.fn.fnamemodify(g_utils.path.remove_last_slash(g_utils.path.unify_slash(dir)), ":t")
end

M.transfer_extra_params = function(source, target)
  if source.__extra__ == nil then
    return target
  end
  target.__extra__ = source.__extra__
  return target
end

M.scan_result = {}
--- @param result WS.Scanner.Result
M.scan_result.is_workspace = function(result)
  -- print("🪚 result: " .. vim.inspect({ result.type, #result.children }))
  return result.type ~= nil and result.children ~= nil
end
--- @param result WS.Scanner.Result
M.scan_result.get_name = function(result)
  local is_workspace = M.scan_result.is_workspace(result)
  return is_workspace and result.type or result.name
end

--- @param result WS.Scanner.Result[]
M.scan_result.add_id = function(result)
  --- @param source WS.Scanner.Result
  local function add_id(source, parent_id)
    source.id = parent_id .. "/" .. M.scan_result.get_name(source)
    if M.scan_result.is_workspace(source) then
      for _, child in ipairs(source.children) do
        add_id(child, source.id)
      end
      return
    end
  end

  for key, value in pairs(result) do
    local is_array_index = g_utils.data.is_array_index(key)
    if is_array_index then
      add_id(value, "")
    else
      add_id(value, "/" .. key) -- key is `type_or_project_name`
    end
  end

  return result
end

return M
