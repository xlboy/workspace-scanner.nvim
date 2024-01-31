local s_utils = require("workspace-scanner.scanner").utils
local g_utils = require("workspace-scanner.utils")

local M = {}

--- 通过 name, level
--- @param source WS.Scanner.Result[]
--- @return WS.Scanner.Result[]
function M.default(source)
  local get_name = s_utils.scan_result.get_name
  local get_level_from_extra = function(t)
    if t.__extra__ == nil then
      return nil
    end
    return t.__extra__.level
  end

  local level_group = vim.tbl_filter(function(s)
    return get_level_from_extra(s) ~= nil
  end, source)

  local name_group = vim.tbl_filter(function(s)
    return get_level_from_extra(s) == nil
  end, source)

  table.sort(level_group, function(a, b)
    local a_level = get_level_from_extra(a)
    local b_level = get_level_from_extra(b)

    if a_level == b_level then
      return get_name(a) < get_name(b)
    end
    return a_level > b_level
  end)

  table.sort(name_group, function(a, b)
    return get_name(a) < get_name(b)
  end)

  return vim.list_extend(level_group, name_group)
end

--- @param entries { source: WS.Scanner.Result }[]
--- @param history_source WS.Picker.History.RecentItem[]
--- @param is_target_entry? fun(entry: { source: WS.Scanner.Result }, item: WS.Picker.History.RecentItem): boolean
function M.recent(entries, history_source, is_target_entry)
  if g_utils.data.is_empty_table(history_source) then
    return entries
  end

  local entry_id_map = {} --- @type table<WS.Scanner.Result.Id, WS.Scanner.Result>
  for _, item in ipairs(history_source) do
    for i, entry in ipairs(entries) do
      local is_target = false
      if is_target_entry ~= nil then
        is_target = is_target_entry(entry, item)
      else
        is_target = entry.source.id == item.id
      end
      if is_target then
        entry_id_map[item.id] = entry
        table.remove(entries, i)
        break
      end
    end
  end

  -- 因为 History.Recent 已经排序过了，所以这里不需要再排序了

  for _, item in ipairs(history_source) do
    local entry = entry_id_map[item.id]
    if entry then
      table.insert(entries, 1, entry)
    end
  end

  return entries
end

--- @param entries { source: WS.Scanner.Result }[]
--- @param history_source WS.Picker.History.PinItem[]
function M.pin(entries, history_source)
  if g_utils.data.is_empty_table(history_source) then
    return entries
  end

  local entry_id_map = {} --- @type table<WS.Scanner.Result.Id, WS.Scanner.Result>
  for _, item in ipairs(history_source) do
    for i, entry in ipairs(entries) do
      if entry.source.id == item.id then
        entry_id_map[item.id] = entry
        table.remove(entries, i)
        break
      end
    end
  end

  -- 因为 History.Pin 已经排序过了，所以这里不需要再排序了

  for _, item in ipairs(history_source) do
    local entry = entry_id_map[item.id]
    if entry then
      table.insert(entries, 1, entry)
    end
  end

  return entries
end

return M
