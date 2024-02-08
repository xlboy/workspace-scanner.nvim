# workspace-scanner.nvim

[English](./README.md) | 简体中文

一个丰富的工作区管理器，它极其注重用户体验及追求最佳性能，它不内置绑定任何 session 插件，但提供了相关钩子来供用户自由绑定

> [WIP] 功能已开发完成，且自用过一段时间，文档处于待完善状态

## 特性

<details>
<summary>1.  <strong>项目定义的灵活性</strong>：可以以多种格式定义工作区项目</summary><br>

```lua
local workspaces_source = {
  -- 定义一个名为 `web` 的工作区
  web = {
    -- `w_dir` -> `workspace_dir`
    -- 定义一个名为 `ui_libs` 的工作区，它会将 `~/projects/web/__ui-libs__/` 路径下包含 `package.json` 文件的所有子文件夹视为独立的工作区项目
    ui_libs = { w_dir = "~/projects/web/__ui-libs__/", patterns = { "package.json" } },
    -- 定义一个名为 `temp_scripts` 的工作区，它会将 `~/projects/web/__temp__/` 路径下的所有子文件夹视为独立的工作区项目
    temp_scripts = { w_dir = "~/projects/web/__temp__/", patterns = "*" },
  },
  -- 定义一个名为 `nvim` 的工作区
  nvim = {
    -- 定义一个名为 `my_config` 的工作区项目
    my_config = "~/.config/nvim/",
    -- 定义一个名为 `lazy` 的工作区，它会将 `lazy.nvim` 插件安装目录下的所有子文件夹视为独立的工作区项目
    lazy = { w_dir = vim.fn.stdpath("data") .. "/lazy/", patterns = "*" },
    -- 将 `~/project/nvim/` 路径下的所有子文件夹视为 `nvim` 工作区的项目
    { w_dir = "~/project/nvim/", patterns = "*" },
  },
}
```

---

</details>

<details>
<summary>2.  <strong>项目选择器（Telescope Picker）</strong>：包含一个用于显示项目的选择器功能。可以以树形（tree）或扁平（flat）的方式显示项目</summary><br>

- **树形（tree）**

  https://github.com/xlboy/workspace-scanner.nvim/assets/63690944/88e705a6-338c-43b7-bf02-bf6f61dfad47

- **扁平（flat）**

  https://github.com/xlboy/workspace-scanner.nvim/assets/63690944/2df271cc-d2ba-491a-b167-8d3f1b4354cb

---

</details>

<details>
<summary>3.  <strong>历史记录功能（History Recent/Pin）</strong>：Recent - 记录最近使用情况；Pin - 将常用项目固定住</summary><br>

- **Recent**

  https://github.com/xlboy/workspace-scanner.nvim/assets/63690944/b6c0aef0-656c-4a5c-a7be-e889e7492e35

- **Pin**

  https://github.com/xlboy/workspace-scanner.nvim/assets/63690944/c8aeefce-02a5-4625-8d39-d9720d2af82c

---

</details>

## 要求

- Neovim >= **0.9.0**
- Telescope

## 安装

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  "xlboy/workspace-scanner.nvim",
  lazy = true,
  ---@type WS.Config
  opts = {},
}
```

## 如何使用？

> 可通过 [我的配置](https://ray.so/#padding=16&theme=breeze&title=xlboy%2Fworkspace-scanner.lua&language=lua&background=true&code=cmV0dXJuIHsKICAieGxib3kvd29ya3NwYWNlLXNjYW5uZXIubnZpbSIsCiAgLS0tIEB0eXBlIFdTLkNvbmZpZwogIG9wdHMgPSB7CiAgICBzY2FubmVyID0gewogICAgICBzb3VyY2UgPSB7CiAgICAgICAgbnZpbSA9IHsKICAgICAgICAgIG15X2NvbmZpZyA9IHsgcF9kaXIgPSAiQzovVXNlcnMvQWRtaW5pc3RyYXRvci9BcHBEYXRhL0xvY2FsL252aW0iLCBfX2V4dHJhX18gPSB7IGxldmVsID0gMiB9IH0sCiAgICAgICAgICB3ZXp0ZXJtID0gIkM6L1VzZXJzL0FkbWluaXN0cmF0b3IvLmNvbmZpZy93ZXp0ZXJtIiwKICAgICAgICAgIGxhenkgPSB7IHdfZGlyID0gdmltLmZuLnN0ZHBhdGgoImRhdGEiKSAuLiAiL2xhenkiIH0sCiAgICAgICAgICB7IHdfZGlyID0gIkQ6L3Byb2plY3QvbnZpbSIgfSwKICAgICAgICAgIGRhdGEgPSB2aW0uZm4uc3RkcGF0aCgiZGF0YSIpLAogICAgICAgICAgX19leHRyYV9fID0geyBsZXZlbCA9IDEgfSwKICAgICAgICB9LAogICAgICAgIGNwcCA9IHsgd19kaXIgPSAiRDovcHJvamVjdC9jcHAiIH0sCiAgICAgICAgd2ViID0geyB3X2RpciA9ICJEOi9wcm9qZWN0L3dlYiIsIF9fZXh0cmFfXyA9IHsgbGV2ZWwgPSAyIH0gfSwKICAgICAgfSwKICAgIH0sCiAgICAtLS0gQHR5cGUgV1MuQ29uZmlnLlBpY2tlcgogICAgcGlja2VyID0gewogICAgICBldmVudHMgPSB7CiAgICAgICAgLS0tIEBwYXJhbSBlbnRyeSBXUy5QaWNrZXIuU2VsZWN0ZWRFbnRyeQogICAgICAgIG9uX3NlbGVjdCA9IGZ1bmN0aW9uKGVudHJ5KQogICAgICAgICAgLS0gcmVzZXNzaW9uLnNhdmVfY3dkKCkKICAgICAgICAgIC0tIHJlcXVpcmUoImNsb3NlX2J1ZmZlcnMiKS5kZWxldGUoeyB0eXBlID0gImFsbCIgfSkKICAgICAgICAgIC0tIHZpbS5jbWQoImNkICIgLi4gZW50cnkuc291cmNlLmRpcikKICAgICAgICAgIC0tIHJlc2Vzc2lvbi5sb2FkX2N3ZCgpCiAgICAgICAgZW5kLAogICAgICB9LAogICAgICB0cmVlX29wdHMgPSB7CiAgICAgICAgd29ya3NwYWNlID0gewogICAgICAgICAgaGlzdG9yeV9yZWNlbnQgPSB7CiAgICAgICAgICAgIGljb24gPSBmYWxzZSwKICAgICAgICAgIH0sCiAgICAgICAgfSwKICAgICAgICBrZXltYXBzID0gewogICAgICAgICAgYmFjayA9ICI8TGVmdD4iLAogICAgICAgICAgZm9yd2FyZCA9ICI8UmlnaHQ%2BIiwKICAgICAgICB9LAogICAgICB9LAogICAgfSwKICB9LAogIGtleXMgPSB7CiAgICB7ICI8bGVhZGVyPmZwbyIsICI8Y21kPmx1YSByZXF1aXJlKCd3b3Jrc3BhY2Utc2Nhbm5lcicpLnJlZnJlc2goKTxjcj4iLCBkZXNjID0gIlt3b3Jrc3BhY2Utc2Nhbm5lcl0gUmVmcmVzaCIgfSwKICAgIHsKICAgICAgIjxsZWFkZXI%2BZnByIiwKICAgICAgZnVuY3Rpb24oKQogICAgICAgIHJlcXVpcmUoIndvcmtzcGFjZS1zY2FubmVyIikuc2hvd19waWNrZXIoewogICAgICAgICAgc2hvd19oaXN0b3J5X29ubHkgPSB0cnVlLAogICAgICAgICAgdGVsZXNjb3BlID0gewogICAgICAgICAgICBvcHRzID0gewogICAgICAgICAgICAgIHByb21wdF90aXRsZSA9ICJSZWNlbnQgUHJvamVjdHMgKEZsYXQpIiwKICAgICAgICAgICAgICBsYXlvdXRfY29uZmlnID0geyB3aWR0aCA9IDkwLCBoZWlnaHQgPSAyNSB9LAogICAgICAgICAgICB9LAogICAgICAgICAgfSwKICAgICAgICAgIGhpc3RvcnkgPSB7CiAgICAgICAgICAgIHJlY2VudCA9IHsgaWNvbiA9IGZhbHNlIH0sCiAgICAgICAgICB9LAogICAgICAgIH0pCiAgICAgIGVuZCwKICAgICAgZGVzYyA9ICJbd29ya3NwYWNlLXNjYW5uZXJdIFNob3cgUmVjZW50IiwKICAgIH0sCiAgICB7CiAgICAgICI8bGVhZGVyPmZwYSIsCiAgICAgIGZ1bmN0aW9uKCkKICAgICAgICByZXF1aXJlKCJ3b3Jrc3BhY2Utc2Nhbm5lciIpLnNob3dfcGlja2VyKHsKICAgICAgICAgIG1vZGUgPSAidHJlZSIsCiAgICAgICAgICBzaG93X2hpc3Rvcnlfb25seSA9IGZhbHNlLAogICAgICAgICAgdGVsZXNjb3BlID0gewogICAgICAgICAgICBvcHRzID0gewogICAgICAgICAgICAgIHByb21wdF90aXRsZSA9ICJBbGwgUHJvamVjdHMgKFRyZWUpIiwKICAgICAgICAgICAgICBsYXlvdXRfY29uZmlnID0geyB3aWR0aCA9IDkwLCBoZWlnaHQgPSAyNSB9LAogICAgICAgICAgICB9LAogICAgICAgICAgfSwKICAgICAgICB9KQogICAgICBlbmQsCiAgICAgIGRlc2MgPSAiW3dvcmtzcGFjZS1zY2FubmVyXSBTaG93IFBpY2tlciIsCiAgICB9LAogIH0sCn0%3D&darkMode=true) 了解相关信息

1. 配置工作区项目

```lua
local source = {
  web = { w_dir = "..." },
  my_nvim_config = "...",
}
require("workspace-scanner").setup({
  -- ...
  scanner = { source = source },
  -- ...
})
```

2. 刷新工作区缓存

> 扫描器会自动将扫描到的工作区项目进行本地缓存，这样后续在启动时就无需每次都扫描（如果每次启动都扫描会带来大量耗时）

> 也就是说，后续工作区项目如果有变动，需要手动刷新缓存

```lua
require("workspace-scanner").refresh()
```

3. 根据自己的喜好弹出 Picker

```lua
-- 具体参数内容可阅读 [配置介绍]
require("workspace-scanner").show_picker({ ... })

-- 个人使用情况：
-- 1. 如果要展示所有项目，则采用 Tree式（这样不会带来项目太多的困扰，可以循序渐进）
require("workspace-scanner").show_picker({
  mode = "tree",
  telescope = {
    opts = {
      prompt_title = "All Projects (Tree)",
    },
  },
})
-- 2. 如果只展示最近工作的项目，则采用 Flat式
require("workspace-scanner").show_picker({
  show_history_only = true,
  telescope = {
    opts = {
      prompt_title = "Recent Projects (Flat)",
    },
  },
})
```

4. 定制 Picker 选择回调

```lua
require("workspace-scanner").setup({
  picker = {
    events = {
      --- @param entry WS.Picker.SelectedEntry
      on_select = function(entry)
        -- `entry.source.dir` 为选中的项目路径
        -- 接下来你可以做自己想做的事了，比如：切换 cwd 为选中的项目路径
        -- vim.cmd("cd " .. entry.source.dir)

        -- 或是刷新 session 等
      end,
    },
  },
})
```

## 配置介绍

<details>
<summary>展开默认配置</summary><br>

```lua
--- @class WS.Config
local _default_config = {
  scanner = {
    source = {},
    cache_path = vim.fn.stdpath("data") .. "/workspace-scanner" .. "/scan-result-cache.json",
    patterns = { "README.md", ".git", ".hg", ".svn", ".project", ".root", "package.json" },
  },
  --- @class WS.Config.Picker
  picker = {
    mode = "flat", --- @type "flat" | "tree"
    flat_opts = {
      --- If true, includes tree history (pin/recent)
      include_tree_history = true,
      separator = " > ",
    },
    tree_opts = {
      --- If true, includes flat history (pin/recent)
      include_flat_history = true,
      workspace = {
        icon = "📁", --- @type string | false
        history_recent = {
          enabled = true,
          --- @type boolean
          --- If true, adopts the latest data from all its project nodes
          derive_from_children = true,
          icon = "🕒", --- @type string | false
        },
      },
      keymaps = {
        back = "<C-h>",
        forward = "<C-l>",
      },
    },
    --- @type nil | WS.Scanner.Result[]
    --- If nil, use scanner cache
    pick_source = nil,
    --- If true, show only history
    show_history_only = false,
    history = {
      recent = {
        enabled = true,
        cache_path = vim.fn.stdpath("data") .. "/workspace-scanner" .. "/picker-recent-history.json",
        keymaps = { delete = "<C-d>" },
        icon = "🕒", --- @type string | false
      },
      pin = {
        enabled = true,
        cache_path = vim.fn.stdpath("data") .. "/workspace-scanner" .. "/picker-pin-history.json",
        keymaps = { toggle = "<C-g>" },
        icon = "📌", --- @type string | false
      },
    },
    telescope = {
      --- Telescope configuration: https://github.com/nvim-telescope/telescope.nvim/blob/master/doc/telescope.txt#L87
      opts = {
        layout_config = { height = 25, width = 110 },
      },
    },
    events = {
      --- Hook executed after selecting elements in Picker
      --- @param entry WS.Picker.SelectedEntry
      on_select = function(entry)
        vim.cmd("cd " .. entry.source.dir)
      end,
    },
  },
}
```

</details>
