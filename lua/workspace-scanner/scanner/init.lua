local g_utils = require("workspace-scanner.utils")
local s_config = require("workspace-scanner.config").scanner

local M = {}

M.utils = require("workspace-scanner.scanner.utils")
M.cache = require("workspace-scanner.scanner.cache")

--- @param source WorkspaceObj
--- @return WS.Scanner.ResultOnlyProject[]
function M.scan_workspace(source)
  local normalized_w_dir = g_utils.path.normalize(source.w_dir)

  if vim.fn.isdirectory(normalized_w_dir) ~= 1 then
    return {}
  end

  local projects = {} --- @type WS.Scanner.ResultOnlyProject[]
  local patterns = type(source.patterns) == "string" and { source.patterns } or (source.patterns or s_config.patterns)
  local sub_dirs = M.utils.get_sub_dirs(normalized_w_dir)

  if #sub_dirs == 0 then
    return {}
  end

  for _, sub_dir in ipairs(sub_dirs) do
    ---@diagnostic disable-next-line: param-type-mismatch
    for _, pattern in ipairs(patterns) do
      local exist = vim.fn.glob(sub_dir .. pattern, false) ~= ""
      if exist then
        table.insert(
          projects,
          M.utils.transfer_extra_params(source, { name = M.utils.get_dir_name(sub_dir), dir = sub_dir })
        )
        goto continue
      end
    end
    ::continue::
  end

  return projects
end

--- @param source WS.Scanner.Source
--- @return WS.Scanner.Result[]
M.scan = function(source)
  local u = {
    is_project_dir_str = function(s)
      return type(s) == "string"
    end,
    is_project_dir_obj = function(o)
      return type(o) == "table" and type(o.p_dir) == "string"
    end,
    is_workspace_obj = function(o)
      return type(o) == "table" and type(o.w_dir) == "string"
    end,
  }

  --- @param _source WS.Scanner.Source
  --- @return WS.Scanner.Result[] | WS.Scanner.Result
  local function handle(_source)
    -- `"path/to/config"` -> `{ name = "config", dir = "path/to/config" }`
    if u.is_project_dir_str(_source) then
      return { name = M.utils.get_dir_name(_source), dir = g_utils.path.unify_slash(_source) }
    end
    -- `{ p_dir = "path/to/config" }` -> `{ name = "config", dir = "path/to/config" }`
    if u.is_project_dir_obj(_source) then
      return M.utils.transfer_extra_params(_source, {
        name = _source.name or M.utils.get_dir_name(_source.p_dir),
        dir = g_utils.path.unify_slash(_source.p_dir),
      })
    end
    -- `{ w_dir = "path/to/workspace" }` -> `{ ...<workspace-sub-projects> }`
    if u.is_workspace_obj(_source) then
      ---@diagnostic disable-next-line: param-type-mismatch
      return M.scan_workspace(_source)
    end

    local result = {} --- @type WS.Scanner.Result[]

    ---@diagnostic disable-next-line: param-type-mismatch
    for type_or_project_name, value in g_utils.data.pairs_by_keys(_source) do
      if type_or_project_name == "__extra__" then
        goto continue
      end
      if g_utils.data.is_array_index(type_or_project_name) then
        local r = handle(value)
        if g_utils.data.is_array(r) then
          g_utils.data.append_arrays(result, r)
        else
          table.insert(result, r)
        end
        goto continue
      end

      -- `{ config = "path/to/config" }` -> `{ name = "config", dir = "path/to/config" }`
      if u.is_project_dir_str(value) then
        table.insert(result, { name = type_or_project_name, dir = g_utils.path.unify_slash(value) })
        goto continue
      end

      -- `{ config = { p_dir = "path/to/config" } }` -> `{ name = "config", dir = "path/to/config" }
      if u.is_project_dir_obj(value) then
        table.insert(
          result,
          M.utils.transfer_extra_params(
            value,
            { name = type_or_project_name, dir = g_utils.path.unify_slash(value.p_dir) }
          )
        )
        goto continue
      end

      -- `{ config = { w_dir = "path/to/workspace" } }` -> `{ type = "config", children = { ...<workspace-sub-projects> } }`
      if u.is_workspace_obj(value) then
        table.insert(
          result,
          M.utils.transfer_extra_params(value, { type = type_or_project_name, children = M.scan_workspace(value) })
        )
        goto continue
      end

      table.insert(
        result,
        M.utils.transfer_extra_params(value, { type = type_or_project_name, children = handle(value) })
      )
      ::continue::
    end

    return result
  end

  local result_without_id = handle(source)
  if g_utils.data.is_empty_table(result_without_id) then
    return {}
  end

  if g_utils.data.is_array(result_without_id) == false then
    result_without_id = { result_without_id }
  end
  local result_with_id = M.utils.scan_result.add_id(result_without_id)
  return result_with_id
end

function M.init() end

return M

-- region     *========= Types =========*

--- @alias WS.Scanner.Source WorkspaceObj | ProjectSource | table<WS.Scanner.Source.TypeName | ArrayIndex, WS.Scanner.Source>
--- @alias WS.Scanner.Source.TypeName string -- { [<TypeName>] = <Project_Or_Workspace__Source> }

--- @alias ArrayIndex integer
--- @alias WS.Scanner.Result.Id string -- "a/b/c"

-- region     *========= Result =========*

--- @alias WS.Scanner.Result WS.Scanner.ResultWithType | WS.Scanner.ResultOnlyProject

--- @class WS.Scanner.ResultWithType
--- @field id WS.Scanner.Result.Id
--- @field type WS.Scanner.Source.TypeName
--- @field children WS.Scanner.Result[] -- FIX: 这里一会需要确认一下…
--- @field __extra__? any

--- @class WS.Scanner.ResultOnlyProject
--- @field id WS.Scanner.Result.Id
--- @field name string
--- @field dir string
--- @field __extra__? any

-- endregion  *========= Result =========*

-- region     *========= Project =========*

--- @alias ProjectSource ProjectDirStr | ProjectDirObj

--- @alias ProjectDirStr string

--- @class ProjectDirObj
--- @field p_dir string
--- @field name? string
--- @field __extra__? any

-- endregion  *========= Project =========*

--- @class WorkspaceObj
--- @field w_dir string
--- @field patterns string | string[]? -- default: config.patterns
--- @field __extra__? any

-- endregion  *========= Types =========*
