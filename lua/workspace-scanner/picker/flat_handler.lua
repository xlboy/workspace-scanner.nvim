local t_pickers = require("telescope.pickers")
local t_finders = require("telescope.finders")
local t_actions = require("telescope.actions")
local t_actions_state = require("telescope.actions.state")
local t_config = require("telescope.config")
local t_pickers_entry_display = require("telescope.pickers.entry_display")

local sorter = require("workspace-scanner.picker.sorter")
local history = require("workspace-scanner.picker.history")
local g_utils = require("workspace-scanner.utils")
local s_utils = require("workspace-scanner.scanner").utils

local M = {}

--- @param opts WS.Config.Picker
--- @return FlatPickEntry[]
local function get_pick_entries(opts)
  local pick_entries = {} --- @type FlatPickEntry[]
  local h_recent_opts = opts.history.recent
  local h_pin_opts = opts.history.pin

  --- @param sorted_source WS.Scanner.Result[]
  local function add(sorted_source)
    for _, item in ipairs(sorted_source) do
      if s_utils.scan_result.is_workspace(item) then
        add(sorter.default(item.children))
      else
        table.insert(pick_entries, { source = item })
      end
    end
  end
  add(sorter.default(opts.pick_source))

  local history_mode = opts.flat_opts.include_tree_history and "all" or "flat"
  if h_recent_opts.enabled then
    local history_source = history.recent.get(history_mode)
    pick_entries = sorter.recent(pick_entries, history_source)
    pick_entries = vim.tbl_map(function(entry)
      for _, item in ipairs(history_source) do
        if item.id == entry.source.id then
          entry.is_recent = true
          break
        end
      end
      return entry
    end, pick_entries)
  end
  if h_pin_opts.enabled then
    local history_source = history.pin.get(history_mode)
    pick_entries = sorter.pin(pick_entries, history_source)
    pick_entries = vim.tbl_map(function(entry)
      for _, item in ipairs(history_source) do
        if item.id == entry.source.id then
          entry.is_pinned = true
          break
        end
      end
      return entry
    end, pick_entries)
  end

  if opts.show_history_only then
    pick_entries = vim.tbl_filter(function(entry)
      return entry.is_recent or entry.is_pinned
    end, pick_entries)
  end

  return pick_entries
end

--- @param opts WS.Config.Picker
local function get_ts_finder(opts)
  local h_recent_opts = opts.history.recent
  local h_pin_opts = opts.history.pin
  local pick_entries = get_pick_entries(opts)

  return t_finders.new_table({
    results = pick_entries,
    entry_maker = function(entry) --- @param entry FlatPickEntry
      local status_icon = (function()
        if entry.is_pinned then
          return h_pin_opts.icon or ""
        end
        if entry.is_recent then
          return h_recent_opts.icon or ""
        end
        return ""
      end)()
      local route = table.concat(g_utils.data.string.split(entry.source.id, "/"), opts.flat_opts.separator)
      local dir = g_utils.path.simplify_path(entry.source.dir, "~")

      local displayer = t_pickers_entry_display.create({
        separator = " ",
        items = {
          { width = 2 }, -- StatusIcon
          { width = 35 }, -- Route
          { remaining = true }, -- Dir
        },
      })

      return {
        display = function()
          return displayer({
            { status_icon },
            { route, "TermCursorNC" },
            { dir, "Comment" },
          })
        end,
        ordinal = route .. " " .. dir,
        route = route,
        dir = dir,
        value = entry,
      }
    end,
  })
end

--- @param map fun(mode: string, key: string, cb: fun(bufnr: integer))
--- @param opts WS.Config.Picker
local function get_ts_attach_mappings(map, opts)
  local h_recent_opts = opts.history.recent
  local h_pin_opts = opts.history.pin
  local flat_opts = opts.flat_opts

  local helpers = {
    get_selected_entry = function()
      return t_actions_state.get_selected_entry().value --- @type FlatPickEntry
    end,
    refresh_picker = function(bufnr)
      local current_picker = t_actions_state.get_current_picker(bufnr)
      current_picker:refresh(get_ts_finder(opts))
    end,
  }

  local events = {
    on_entry = function(bufnr)
      t_actions.close(bufnr)
      local selected_entry = helpers.get_selected_entry()
      local source_id = selected_entry.source.id

      ---@diagnostic disable-next-line: param-type-mismatch
      opts.events.on_select(selected_entry)

      if h_recent_opts.enabled then
        if flat_opts.include_tree_history then
          history.recent.update("all", source_id)
        end
        history.recent.update("flat", source_id)
      end
    end,
    on_delete_recent = function(bufnr)
      local selected_entry = helpers.get_selected_entry()

      if flat_opts.include_tree_history then
        history.recent.delete("all", selected_entry.source.id)
      end
      history.recent.delete("flat", selected_entry.source.id)

      helpers.refresh_picker(bufnr)
    end,
    on_delete_pin = function(bufnr)
      local selected_entry = helpers.get_selected_entry()

      local history_mode = flat_opts.include_tree_history and "all" or "flat"
      local is_pinned = vim.tbl_contains(history.pin.get(history_mode), function(v)
        return v.id == selected_entry.source.id
      end, { predicate = true })
      if is_pinned then
        if flat_opts.include_tree_history then
          history.pin.delete("all", selected_entry.source.id)
        end
        history.pin.delete("flat", selected_entry.source.id)
      else
        local pin_level = vim.fn.input("Enter a pin-level as a number: ")
        pin_level = tonumber(pin_level)
        if pin_level == nil then
          g_utils.basic.notify("Invalid pin-level", "error")
          return
        end
        if flat_opts.include_tree_history then
          history.pin.update("all", selected_entry.source.id, pin_level)
        end
        history.pin.update("flat", selected_entry.source.id, pin_level)
      end

      helpers.refresh_picker(bufnr)
    end,
  }

  map("i", "<CR>", events.on_entry)

  if h_recent_opts.enabled then
    map("i", h_recent_opts.keymaps.delete, events.on_delete_recent)
  end

  if h_pin_opts.enabled then
    map("i", h_pin_opts.keymaps.toggle, events.on_delete_pin)
  end
end

--- @param opts WS.Config.Picker
function M.show(opts)
  t_pickers
    .new(opts.telescope.opts, {
      prompt_title = "Project Picker",
      sorter = t_config.values.generic_sorter({}),
      attach_mappings = function(_, map)
        get_ts_attach_mappings(map, opts)
        return true
      end,
      finder = get_ts_finder(opts),
      previewer = false,
    })
    :find()
end

return M

-- region     *========= Types =========*

--- @class FlatPickEntry
--- @field source WS.Scanner.Result
--- @field is_pinned? boolean
--- @field is_recent? boolean

--#endregion  *========= Types =========*
