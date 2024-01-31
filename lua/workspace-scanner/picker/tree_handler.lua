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

local M = {
  state = {
    stack = {}, --- @type { source: WS.Scanner.ResultWithType, selection_index: number }[]
  },
}

--- @param opts WS.Config.Picker
--- @return TreePickEntry[]
local function get_pick_entries(opts)
  print("哈哈，重来了，操你妈的")
  local h_recent_opts = opts.history.recent
  local h_pin_opts = opts.history.pin
  local tree_opts = opts.tree_opts

  local pick_source = #M.state.stack == 0 --[[ is root ]]
      and opts.pick_source
    or M.state.stack[#M.state.stack].source.children

  --- @type TreePickEntry[]
  local pick_entries = vim.tbl_map(function(sorted_source) --- @param sorted_source WS.Scanner.Result
    return {
      source = sorted_source,
      is_workspace = s_utils.scan_result.is_workspace(sorted_source),
    }
  end, sorter.default(pick_source))

  local history_mode = tree_opts.include_flat_history and "all" or "tree"
  if h_recent_opts.enabled then
    local history_source = history.recent.get(history_mode)
    pick_entries = sorter.recent(pick_entries, history_source, function(entry, item)
      ---@diagnostic disable-next-line: undefined-field
      return not entry.is_workspace and entry.source.id == item.id
    end)
    pick_entries = vim.tbl_map(function(entry)
      if entry.is_workspace then -- 后面会有专门的处理
        return entry
      end
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
      if entry.is_workspace then -- 后面会有专门的处理
        return entry
      end

      for _, item in ipairs(history_source) do
        if item.id == entry.source.id then
          entry.is_pinned = true
          break
        end
      end
      return entry
    end, pick_entries)
  end

  (function --[[handle workspace]]()
    local workspace_entries = {} --- @type TreePickEntry[]

    local remove_indices = {}
    for i, entry in ipairs(pick_entries) do
      if entry.is_workspace then
        table.insert(workspace_entries, entry)
        table.insert(remove_indices, i)
      end
    end
    for i = #remove_indices, 1, -1 do
      table.remove(pick_entries, remove_indices[i])
    end

    -- 影响排序的只有 recent, pin 只会单纯的会呈现出来（不会影响排序）
    local h_pin_source = history.pin.get(history_mode)
    local h_recent_source = history.recent.get(history_mode)

    --- @alias WorkspaceId WS.Scanner.Result.Id
    --- @type table<WorkspaceId, { latest_recent_ts?: number, pin_level?: number }>
    --- `latest_recent_ts` 只取 self/child 的；`pin_level` 只取 self 的
    local temp_ws_infos = {}

    for _, entry in ipairs(workspace_entries) do
      local ws_id = entry.source.id
      local pin_level = nil
      local latest_recent_ts = nil

      if h_pin_opts.enabled then
        for _, item in ipairs(h_pin_source) do
          local is_self = item.id == ws_id
          if is_self then
            pin_level = item.level
            break
          end
        end
      end

      if h_recent_opts.enabled and tree_opts.workspace.history_recent.enabled then
        for _, item in ipairs(h_recent_source) do
          if tree_opts.workspace.history_recent.derive_from_children then
            local is_child = vim.startswith(item.id, ws_id .. "/")
            if is_child then
              local is_child_workspace = item.__extra__ and item.__extra__.is_workspace
              if not is_child_workspace then
                if latest_recent_ts == nil or item.timestamp > latest_recent_ts then
                  latest_recent_ts = item.timestamp
                end
              end
            end
          else
            local is_self = item.id == ws_id
            if is_self then
              latest_recent_ts = item.timestamp
              break
            end
          end
        end
      end

      temp_ws_infos[ws_id] = { pin_level = pin_level, latest_recent_ts = latest_recent_ts }
      entry.is_pinned = pin_level ~= nil
      entry.is_recent = latest_recent_ts ~= nil
    end

    -- 取出没有 recent, pin 的 workspace，然后从 workspace_entries 中移除，再交给 sorter.default 排序，随后再插入到 workspace_entries 后面
    local no_history_ws_entries = {} --- @type TreePickEntry[]
    local has_history_ws_entries = {} --- @type TreePickEntry[]

    for _, entry in ipairs(workspace_entries) do
      if not entry.is_recent and not entry.is_pinned then
        table.insert(no_history_ws_entries, 1, entry)
      else
        table.insert(has_history_ws_entries, entry)
      end
    end

    -- 根据 recent, pin 排序，recent 在前，pin 在后
    table.sort(has_history_ws_entries, function(a, b)
      local a_info = temp_ws_infos[a.source.id]
      local b_info = temp_ws_infos[b.source.id]

      if a.is_recent and b.is_recent then
        return a_info.latest_recent_ts < b_info.latest_recent_ts
      end
      if a.is_recent and not b.is_pinned and not b.is_recent then
        return false
      end
      if b.is_recent and not a.is_pinned and not a.is_recent then
        return true
      end

      if a.is_pinned and b.is_pinned then
        return a_info.pin_level < b_info.pin_level
      end
      if a.is_pinned and not b.is_pinned then
        return false
      end
      if not a.is_pinned and b.is_pinned then
        return true
      end

      return false
    end)

    local sorted_ws_entries = vim.list_extend(no_history_ws_entries, has_history_ws_entries)

    for _, entry in ipairs(sorted_ws_entries) do
      table.insert(pick_entries, 1, entry)
    end
  end)()

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
  local tree_opts = opts.tree_opts
  local pick_entries = get_pick_entries(opts)

  return t_finders.new_table({
    results = pick_entries,
    entry_maker = function(entry) --- @param entry TreePickEntry
      local status_icon = (function()
        if entry.is_pinned then
          return h_pin_opts.icon or ""
        end
        if entry.is_recent then
          if entry.is_workspace then
            if tree_opts.workspace.history_recent.enabled then
              return tree_opts.workspace.history_recent.icon or ""
            else
              return ""
            end
          end
          return h_recent_opts.icon or ""
        end
        return ""
      end)()
      local workspace_icon = entry.is_workspace and (opts.tree_opts.workspace.icon or "") or ""
      local name = entry.is_workspace and entry.source.type or entry.source.name
      local dir = entry.is_workspace and "" or g_utils.path.simplify_path(entry.source.dir, "~")

      local displayer = t_pickers_entry_display.create({
        separator = " ",
        items = {
          { width = 2 }, -- StatusIcon
          { width = 2 }, -- WorkspaceIcon
          { width = 25 }, -- Name
          { remaining = true }, -- Dir
        },
      })

      return {
        display = function()
          return displayer({
            { workspace_icon },
            { status_icon },
            { name, "TermCursorNC" },
            { dir, "Comment" },
          })
        end,
        ordinal = entry.is_workspace and name or string.format("%s %s", name, dir),
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
  local tree_opts = opts.tree_opts

  local helpers = {
    get_selected_entry = function()
      return t_actions_state.get_selected_entry().value --- @type TreePickEntry
    end,
    get_selection_index = function(bufnr)
      local current_picker = t_actions_state.get_current_picker(bufnr)
      return current_picker:get_selection_row() --- @type number
    end,
    set_selection_index = function(bufnr, index)
      local current_picker = t_actions_state.get_current_picker(bufnr)
      current_picker:set_selection(index)
    end,

    refresh_picker = (function()
      local cur_picker_default_prefix = nil

      return function(bufnr)
        local current_picker = t_actions_state.get_current_picker(bufnr)
        if cur_picker_default_prefix == nil then
          cur_picker_default_prefix = current_picker.prompt_prefix
        end
        local refresh_opts = { reset_prompt = true }

        if #M.state.stack > 0 then
          local current_source = M.state.stack[#M.state.stack].source
          local id_arr = g_utils.data.string.split(current_source.id, "/")
          local id_str = table.concat(id_arr, " / ")
          local has_space = string.match(cur_picker_default_prefix, "^%s") ~= nil
          refresh_opts.new_prefix = id_str .. (has_space and "" or " ") .. cur_picker_default_prefix
        else
          refresh_opts.new_prefix = cur_picker_default_prefix
        end

        current_picker:refresh(get_ts_finder(opts), refresh_opts)
      end
    end)(),
  }

  local events = {
    on_entry = function(bufnr)
      local selected_pick_entry = helpers.get_selected_entry()
      local is_workspace = selected_pick_entry.is_workspace
      local source_id = selected_pick_entry.source.id

      if h_recent_opts.enabled then
        if not is_workspace or tree_opts.workspace.history_recent.enabled then
          if tree_opts.include_flat_history then
            history.recent.update("all", source_id, { is_workspace = is_workspace })
          end
          history.recent.update("tree", source_id, { is_workspace = is_workspace })
        end
      end

      if is_workspace then
        table.insert(
          M.state.stack,
          { source = selected_pick_entry.source, selection_index = helpers.get_selection_index(bufnr) }
        )
        helpers.refresh_picker(bufnr)
        return
      end

      t_actions.close(bufnr)

      ---@diagnostic disable-next-line: param-type-mismatch
      opts.events.on_select(selected_pick_entry)
    end,
    on_back = function(bufnr)
      if #M.state.stack > 0 then
        local prev_selection_index = M.state.stack[#M.state.stack].selection_index
        table.remove(M.state.stack)
        helpers.refresh_picker(bufnr)
        vim.defer_fn(function()
          helpers.set_selection_index(bufnr, prev_selection_index)
        end, 50)
      end
    end,
    on_delete_recent = function(bufnr)
      local source_id = helpers.get_selected_entry().source.id

      if tree_opts.include_flat_history then
        history.recent.delete("all", source_id)
      end
      history.recent.delete("tree", source_id)

      helpers.refresh_picker(bufnr)
    end,
    on_toggle_pin = function(bufnr)
      local source_id = helpers.get_selected_entry().source.id

      local history_mode = tree_opts.include_flat_history and "all" or "tree"
      local is_pinned = vim.tbl_contains(history.pin.get(history_mode), function(v)
        return v.id == source_id
      end, { predicate = true })
      if is_pinned then
        if tree_opts.include_flat_history then
          history.pin.delete("all", source_id)
        end
        history.pin.delete("tree", source_id)
      else
        local pin_level = vim.fn.input("Enter a pin-level as a number: ")
        pin_level = tonumber(pin_level)
        if pin_level == nil then
          g_utils.basic.notify("Invalid pin-level", "error")
          return
        end
        if tree_opts.include_flat_history then
          history.pin.update("all", source_id, pin_level)
        end
        history.pin.update("tree", source_id, pin_level)
      end

      helpers.refresh_picker(bufnr)
    end,
  }

  map("i", "<CR>", events.on_entry)
  map("n", "<CR>", events.on_entry)
  map("i", tree_opts.keymaps.forward, events.on_entry)
  map("i", tree_opts.keymaps.back, events.on_back)
  if h_recent_opts.enabled then
    map("i", h_recent_opts.keymaps.delete, events.on_delete_recent)
  end
  if h_pin_opts.enabled then
    map("i", h_pin_opts.keymaps.toggle, events.on_toggle_pin)
  end
end

--- @param opts WS.Config.Picker
function M.show(opts)
  M.state.stack = {}

  t_pickers
    .new(opts.telescope.opts, {
      prompt_title = "Project Picker",
      sorter = t_config.values.generic_sorter(),
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

--- @class TreePickEntry
--- @field source WS.Scanner.Result
--- @field is_pinned? boolean
--- @field is_recent? boolean
--- @field is_workspace? boolean

--#endregion  *========= Types =========*
