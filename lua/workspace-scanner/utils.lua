local M = {
  path = {
    --- `~/.config/nvim/` -> `/home/username/.config/nvim/`
    normalize = function(path)
      return vim.fn.expand(path) --[[@as string]]
    end,
    --- @return string
    append_slash = function(path)
      if path:sub(-1) ~= "/" then
        return path .. "/"
      end
      return path
    end,
    remove_last_slash = function(path)
      if path:sub(-1) == "/" then
        return path:sub(1, -2)
      end
      return path
    end,
    unify_slash = function(path)
      local new = string.gsub(path, "\\", "/")
      new = string.gsub(new, "//", "/")
      return new
    end,
    simplify_path = function(full_path, home_symbol)
      local home = os.getenv("HOME")
      full_path = vim.fn.expand(full_path) --[[@as string]]
      if home then
        return full_path:gsub("^" .. home, home_symbol)
      else
        return full_path
      end
    end,
    get_dir = function(path)
      return vim.fn.fnamemodify(path, ":h")
    end,
  },
  data = {
    append_arrays = function(t1, ...)
      for _, t in ipairs({ ... }) do
        for i = 1, #t do
          table.insert(t1, t[i])
        end
      end
      return t1
    end,
    is_array = function(t)
      return type(t) == "table" and #t > 0
    end,
    is_object = function(t)
      return type(t) == "table" and #t == 0
    end,
    --- @see https://stackoverflow.com/a/70096863
    pairs_by_keys = function(t, f)
      local string_keys = {}
      local number_keys = {}
      for k in pairs(t) do
        if type(k) == "number" then
          table.insert(number_keys, k)
        else
          table.insert(string_keys, k)
        end
      end
      table.sort(string_keys, f)
      table.sort(number_keys, f)

      local all = {}
      for _, v in ipairs(string_keys) do
        table.insert(all, v)
      end
      for _, v in ipairs(number_keys) do
        table.insert(all, v)
      end

      local i = 0 -- iterator variable
      local iter = function() -- iterator function
        i = i + 1
        if all[i] == nil then
          return nil
        else
          return all[i], t[all[i]]
        end
      end

      return iter
    end,
    is_array_index = function(t)
      if type(t) == "number" and t > 0 then
        return true
      end
      return tonumber(t) ~= nil and tonumber(t) > 1
    end,
    is_empty_table = function(t)
      return t == nil or next(t) == nil
    end,
    string = {
      split = function(str, sep)
        local result = {}
        local regex = ("([^%s]+)"):format(sep)
        for each in str:gmatch(regex) do
          table.insert(result, each)
        end
        return result
      end,
    },
  },
  file = {
    write_json = function(path, data)
      local f = io.open(path, "w")
      if f == nil then
        return
      end
      f:write(vim.fn.json_encode(data))
      f:close()
    end,
    read_json = function(path)
      local f = io.open(path, "r")
      if f == nil then
        return nil
      end
      local content = f:read("*all")
      f:close()
      return vim.fn.json_decode(content)
    end,
    mkdir_dir = function(dir)
      if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
      end
    end,
    exists = function(path)
      return vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
    end,
  },
  basic = {
    notify = function(msg, level)
      local levels = {
        error = vim.log.levels.ERROR,
        warn = vim.log.levels.WARN,
        info = vim.log.levels.INFO,
      }
      vim.notify(msg, levels[level], { title = "workspace-scanner.nvim" })
    end,
  },
}

return M
