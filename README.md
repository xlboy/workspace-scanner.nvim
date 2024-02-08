# workspace-scanner.nvim

[简体中文](./README.zh.md) | English

A sophisticated workspace manager, it places great emphasis on user experience and strives for optimal performance. It does not natively bind to any session plugins, but it provides relevant hooks for users to bind freely.

> [WIP] The feature development is completed, and it has been used for a while. The documentation is in the process of being perfected.

## Features

<details>
<summary>1.  <strong>Flexibility of Project Definition</strong>: It allows defining workspace projects in multiple formats</summary><br>

```lua
local workspaces_source = {
  -- Define a workspace named `web`
  web = {
    -- `w_dir` -> `workspace_dir`
    -- Define a workspace named `ui_libs`, It treats all subfolders containing `package.json` in the `~/projects/web/__ui-libs__/` path as independent workspace projects
    ui_libs = { w_dir = "~/projects/web/__ui-libs__/", patterns = { "package.json" } },
    -- Define a workspace named `temp_scripts`, It treats all the subfolders in the `~/projects/web/__temp__/` path as independent workspace projects
    temp_scripts = { w_dir = "~/projects/web/__temp__/", patterns = "*" },
  },
  -- Define a workspace named `nvim`
  nvim = {
    -- Define a workspace project named `my_config`
    my_config = "~/.config/nvim/",
    -- Define a workspace named `lazy`, It treats all subfolders in the `lazy.nvim` plugin installation directory as independent workspace projects
    lazy = { w_dir = vim.fn.stdpath("data") .. "/lazy/", patterns = "*" },
    -- Treats all subfolders in the `~/project/nvim/` path as projects of the `nvim` workspace
    { w_dir = "~/project/nvim/", patterns = "*" },
  },
}
```

---

</details>

<details>
<summary>2.  <strong>Project Selector (Telescope Picker)</strong>: Contains a picker feature for displaying projects. It can display projects in tree or flat layout</summary><br>

- **Tree**

  https://github.com/xlboy/workspace-scanner.nvim/assets/63690944/88e705a6-338c-43b7-bf02-bf6f61dfad47

- **Flat**

  https://github.com/xlboy/workspace-scanner.nvim/assets/63690944/2df271cc-d2ba-491a-b167-8d3f1b4354cb

---

</details>

<details>
<summary>3.  <strong>History Feature (History Recent/Pin)</strong>: Recent - Records recent usage; Pin - Pins frequently used projects</summary><br>

- **Recent**

  https://github.com/xlboy/workspace-scanner.nvim/assets/63690944/b6c0aef0-656c-4a5c-a7be-e889e7492e35

- **Pin**

  https://github.com/xlboy/workspace-scanner.nvim/assets/63690944/c8aeefce-02a5-4625-8d39-d9720d2af82c

---

</details>

## Requirements

- Neovim >= **0.9.0**
- Telescope

## Installation

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  "xlboy/workspace-scanner.nvim",
  lazy = true,
  ---@type WS.Config
  opts = {},
}
```

## How to use?
> You can understand the relevant information through [my configuration](https://ray.so/#padding=16&theme=breeze&title=xlboy%2Fworkspace-scanner.lua&language=lua&background=true&code=cmV0dXJuIHsKICAieGxib3kvd29ya3NwYWNlLXNjYW5uZXIubnZpbSIsCiAgLS0tIEB0eXBlIFdTLkNvbmZpZwogIG9wdHMgPSB7CiAgICBzY2FubmVyID0gewogICAgICBzb3VyY2UgPSB7CiAgICAgICAgbnZpbSA9IHsKICAgICAgICAgIG15X2NvbmZpZyA9IHsgcF9kaXIgPSAiQzovVXNlcnMvQWRtaW5pc3RyYXRvci9BcHBEYXRhL0xvY2FsL252aW0iLCBfX2V4dHJhX18gPSB7IGxldmVsID0gMiB9IH0sCiAgICAgICAgICB3ZXp0ZXJtID0gIkM6L1VzZXJzL0FkbWluaXN0cmF0b3IvLmNvbmZpZy93ZXp0ZXJtIiwKICAgICAgICAgIGxhenkgPSB7IHdfZGlyID0gdmltLmZuLnN0ZHBhdGgoImRhdGEiKSAuLiAiL2xhenkiIH0sCiAgICAgICAgICB7IHdfZGlyID0gIkQ6L3Byb2plY3QvbnZpbSIgfSwKICAgICAgICAgIGRhdGEgPSB2aW0uZm4uc3RkcGF0aCgiZGF0YSIpLAogICAgICAgICAgX19leHRyYV9fID0geyBsZXZlbCA9IDEgfSwKICAgICAgICB9LAogICAgICAgIGNwcCA9IHsgd19kaXIgPSAiRDovcHJvamVjdC9jcHAiIH0sCiAgICAgICAgd2ViID0geyB3X2RpciA9ICJEOi9wcm9qZWN0L3dlYiIsIF9fZXh0cmFfXyA9IHsgbGV2ZWwgPSAyIH0gfSwKICAgICAgfSwKICAgIH0sCiAgICAtLS0gQHR5cGUgV1MuQ29uZmlnLlBpY2tlcgogICAgcGlja2VyID0gewogICAgICBldmVudHMgPSB7CiAgICAgICAgLS0tIEBwYXJhbSBlbnRyeSBXUy5QaWNrZXIuU2VsZWN0ZWRFbnRyeQogICAgICAgIG9uX3NlbGVjdCA9IGZ1bmN0aW9uKGVudHJ5KQogICAgICAgICAgLS0gcmVzZXNzaW9uLnNhdmVfY3dkKCkKICAgICAgICAgIC0tIHJlcXVpcmUoImNsb3NlX2J1ZmZlcnMiKS5kZWxldGUoeyB0eXBlID0gImFsbCIgfSkKICAgICAgICAgIC0tIHZpbS5jbWQoImNkICIgLi4gZW50cnkuc291cmNlLmRpcikKICAgICAgICAgIC0tIHJlc2Vzc2lvbi5sb2FkX2N3ZCgpCiAgICAgICAgZW5kLAogICAgICB9LAogICAgICB0cmVlX29wdHMgPSB7CiAgICAgICAgd29ya3NwYWNlID0gewogICAgICAgICAgaGlzdG9yeV9yZWNlbnQgPSB7CiAgICAgICAgICAgIGljb24gPSBmYWxzZSwKICAgICAgICAgIH0sCiAgICAgICAgfSwKICAgICAgICBrZXltYXBzID0gewogICAgICAgICAgYmFjayA9ICI8TGVmdD4iLAogICAgICAgICAgZm9yd2FyZCA9ICI8UmlnaHQ%2BIiwKICAgICAgICB9LAogICAgICB9LAogICAgfSwKICB9LAogIGtleXMgPSB7CiAgICB7ICI8bGVhZGVyPmZwbyIsICI8Y21kPmx1YSByZXF1aXJlKCd3b3Jrc3BhY2Utc2Nhbm5lcicpLnJlZnJlc2goKTxjcj4iLCBkZXNjID0gIlt3b3Jrc3BhY2Utc2Nhbm5lcl0gUmVmcmVzaCIgfSwKICAgIHsKICAgICAgIjxsZWFkZXI%2BZnByIiwKICAgICAgZnVuY3Rpb24oKQogICAgICAgIHJlcXVpcmUoIndvcmtzcGFjZS1zY2FubmVyIikuc2hvd19waWNrZXIoewogICAgICAgICAgc2hvd19oaXN0b3J5X29ubHkgPSB0cnVlLAogICAgICAgICAgdGVsZXNjb3BlID0gewogICAgICAgICAgICBvcHRzID0gewogICAgICAgICAgICAgIHByb21wdF90aXRsZSA9ICJSZWNlbnQgUHJvamVjdHMgKEZsYXQpIiwKICAgICAgICAgICAgICBsYXlvdXRfY29uZmlnID0geyB3aWR0aCA9IDkwLCBoZWlnaHQgPSAyNSB9LAogICAgICAgICAgICB9LAogICAgICAgICAgfSwKICAgICAgICAgIGhpc3RvcnkgPSB7CiAgICAgICAgICAgIHJlY2VudCA9IHsgaWNvbiA9IGZhbHNlIH0sCiAgICAgICAgICB9LAogICAgICAgIH0pCiAgICAgIGVuZCwKICAgICAgZGVzYyA9ICJbd29ya3NwYWNlLXNjYW5uZXJdIFNob3cgUmVjZW50IiwKICAgIH0sCiAgICB7CiAgICAgICI8bGVhZGVyPmZwYSIsCiAgICAgIGZ1bmN0aW9uKCkKICAgICAgICByZXF1aXJlKCJ3b3Jrc3BhY2Utc2Nhbm5lciIpLnNob3dfcGlja2VyKHsKICAgICAgICAgIG1vZGUgPSAidHJlZSIsCiAgICAgICAgICBzaG93X2hpc3Rvcnlfb25seSA9IGZhbHNlLAogICAgICAgICAgdGVsZXNjb3BlID0gewogICAgICAgICAgICBvcHRzID0gewogICAgICAgICAgICAgIHByb21wdF90aXRsZSA9ICJBbGwgUHJvamVjdHMgKFRyZWUpIiwKICAgICAgICAgICAgICBsYXlvdXRfY29uZmlnID0geyB3aWR0aCA9IDkwLCBoZWlnaHQgPSAyNSB9LAogICAgICAgICAgICB9LAogICAgICAgICAgfSwKICAgICAgICB9KQogICAgICBlbmQsCiAgICAgIGRlc2MgPSAiW3dvcmtzcGFjZS1zY2FubmVyXSBTaG93IFBpY2tlciIsCiAgICB9LAogIH0sCn0%3D&darkMode=true)

1. Configure the Workspace Project

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

2. Refresh Workspace Cache

> The scanner will automatically cache the scanned workspace projects locally, so there is no need to scan every time at startup (if you scan every time at startup, it will take a lot of time)

> In other words, if there are changes in the workspace projects in the future, you need to manually refresh the cache

```lua
require("workspace-sccraper").refresh()
```

3. Present the Picker According to Your Preferences

```lua
-- For specific parameter contents, please read [Configuration Introduction]
require("workspace-scanner").show_picker({ ... })

-- Personal use cases:
-- 1. If you want to display all projects, use the Tree mode (this won't cause too many projects to be an issue, and can be progressive)
require("workspace-scanner").show_picker({
  mode = "tree",
  telescope = {
    opts = {
      prompt_title = "All Projects (Tree)",
    },
  },
})
-- 2. If only the recent projects are displayed, use the Flat mode
require("workspace-scanner").show_picker({
  show_history_only = true,
  telescope = {
    opts = {
      prompt_title = "Recent Projects (Flat)",
    },
  },
})
```

4. Customize Picker Selection Callback

```lua
require("workspace-scanner").setup({
  picker = {
    events = {
      --- @param entry WS.Picker.SelectedEntry
      on_select = function(entry)
        -- `entry.source.dir` is the path of the selected project
        -- Now you can do what you want to do, for example: switch cwd to the path of the selected project
        -- vim.cmd("cd " .. entry.source.dir)

        -- or refresh the session, etc.
      end,
    },
  },
})
```

## Configuration Introduction

<details>
<summary>Expand default configuration</summary><br>


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
