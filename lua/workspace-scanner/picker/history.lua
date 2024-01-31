local g_utils = require("workspace-scanner.utils")

local M = {}

--- @alias HistoryMode WS.Picker.Mode | "all"

M.recent = (function()
  --- @alias WS.Picker.History.RecentItem { timestamp: integer, id: WS.Scanner.Result.Id, __extra__?: table }
  --- @alias WS.Picker.History.Recent table<HistoryMode, WS.Picker.History.RecentItem[]>

  local cache_path = ""
  local cache_data = nil --- @type WS.Picker.History.Recent

  local _find_index = function(mode, id)
    for i, v in ipairs(cache_data[mode]) do
      if v.id == id then
        return i
      end
    end
    return nil
  end

  return {
    --- @param mode HistoryMode
    --- @param id WS.Scanner.Result.Id
    --- @param __extra__? table
    update = function(mode, id, __extra__)
      local timestamp = os.time()
      local item = { timestamp = timestamp, id = id }
      if __extra__ then
        item.__extra__ = __extra__
      end

      local index = _find_index(mode, id)
      if index then
        local old_item = cache_data[mode][index]
        cache_data[mode][index] = vim.tbl_extend("force", old_item, item)
      else
        table.insert(cache_data[mode], item)
      end

      g_utils.file.write_json(cache_path, cache_data)
    end,
    ---  @param mode HistoryMode
    get = function(mode)
      local sorted = cache_data[mode]
      table.sort(sorted, function(a, b)
        return a.timestamp < b.timestamp
      end)

      return sorted
    end,
    --- @param mode HistoryMode
    --- @param id WS.Scanner.Result.Id
    delete = function(mode, id)
      local index = _find_index(mode, id)
      if index then
        table.remove(cache_data[mode], index)
      end

      g_utils.file.write_json(cache_path, cache_data)
    end,
    --- @param opts WS.Config.Picker
    init = function(opts)
      cache_path = g_utils.path.normalize(opts.history.recent.cache_path)
      cache_data = g_utils.file.read_json(cache_path) or { all = {}, flat = {}, tree = {} }
    end,
  }
end)()

M.pin = (function()
  --- @alias WS.Picker.History.PinItem { level: number, id: WS.Scanner.Result.Id }
  --- @alias WS.Picker.History.Pin table<HistoryMode, WS.Picker.History.PinItem[]>

  local cache_path = ""
  local cache_data = nil --- @type WS.Picker.History.Pin

  local _find_index = function(mode, id)
    for i, v in ipairs(cache_data[mode]) do
      if v.id == id then
        return i
      end
    end
    return nil
  end

  return {
    --- @param mode HistoryMode
    --- @param id WS.Scanner.Result.Id
    --- @param level number
    update = function(mode, id, level)
      local item = { level = level, id = id }

      local index = _find_index(mode, id)
      if index then
        cache_data[mode][index] = item
      else
        table.insert(cache_data[mode], item)
      end

      g_utils.file.write_json(cache_path, cache_data)
    end,
    --- @param mode HistoryMode
    get = function(mode)
      local sorted = cache_data[mode]

      table.sort(sorted, function(a, b)
        return a.level < b.level
      end)

      return sorted
    end,
    --- @param mode HistoryMode
    --- @param id WS.Scanner.Result.Id
    delete = function(mode, id)
      local index = _find_index(mode, id)
      if index then
        table.remove(cache_data[mode], index)
      end

      g_utils.file.write_json(cache_path, cache_data)
    end,
    --- @param opts WS.Config.Picker
    init = function(opts)
      cache_path = g_utils.path.normalize(opts.history.pin.cache_path)
      cache_data = g_utils.file.read_json(cache_path) or { all = {}, flat = {}, tree = {} }
    end,
  }
end)()

return M
