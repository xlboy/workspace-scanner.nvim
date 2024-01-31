local g_utils = require("workspace-scanner.utils")
local config = require("workspace-scanner.config")

local cache_data = nil --- @type WS.Scanner.Result[] | nil
local cache_path = ""

local M = {}

function M.refresh()
  local scanner = require("workspace-scanner.scanner")
  cache_data = scanner.scan(config.scanner.source)
  g_utils.file.write_json(cache_path, cache_data)
end

function M.init()
  cache_path = g_utils.path.normalize(config.scanner.cache_path)
  if not g_utils.file.exists(cache_path) then
    g_utils.file.mkdir_dir(g_utils.path.get_dir(cache_path))
  end

  if g_utils.file.exists(cache_path) then
    cache_data = g_utils.file.read_json(cache_path)
  end
end

function M.get()
  return cache_data
end

return M
