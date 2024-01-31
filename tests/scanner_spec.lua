local scanner = require("workspace-scanner.scanner")
local g_utils = require("workspace-scanner.utils")

local test_dir = vim.fn.getcwd() .. "/tests"

local unify_slash = g_utils.path.unify_slash

describe("scanner > ", function()
  describe("_utils > ", function()
    it("get_sub_dirs", function()
      local w_dir = test_dir .. "/__resources__/sub-dirs/"
      local sub_dirs = scanner.utils.get_sub_dirs(w_dir)
      assert.are.same(sub_dirs, { unify_slash(w_dir .. "a/"), unify_slash(w_dir .. "b/") })
    end)

    it("get_dir_name", function()
      local dir = test_dir .. "/__resources__/sub-dirs/a/"
      local dir_name = scanner.utils.get_dir_name(dir)
      assert.are.same(dir_name, "a")
    end)

    it("transfer_extra_params", function()
      local source = { __extra__ = { a = 1 } }
      local target = { b = 2 }
      local result = scanner.utils.transfer_extra_params(source, target)
      assert.are.same(result, { b = 2, __extra__ = { a = 1 } })

      source = { a = 3 }
      target = { b = 2 }
      result = scanner.utils.transfer_extra_params(source, target)
      assert.are.same(result, { b = 2 })

      source = { __extra__ = { a = 1 } }
      target = { b = 2, __extra__ = { c = 3 } }
      result = scanner.utils.transfer_extra_params(source, target)
      assert.are.same(result, { b = 2, __extra__ = { a = 1 } })
    end)
  end)

  describe("scan_workspace > ", function()
    it("default config.patterns", function()
      local w_dir = test_dir .. "/__resources__/web-workspaces/"
      local p_dirs = scanner.scan_workspace({ w_dir = w_dir })
      assert.are.same(p_dirs, {
        { dir = unify_slash(w_dir .. "cli/"), name = "cli" },
        { dir = unify_slash(w_dir .. "ui-library/"), name = "ui-library" },
      })
    end)

    it("custom patterns", function()
      local w_dir = test_dir .. "/__resources__/web-workspaces/"
      local p_dirs = scanner.scan_workspace({ w_dir = w_dir, patterns = { "package.json" } })
      assert.are.same(p_dirs, {
        { dir = unify_slash(w_dir .. "cli/"), name = "cli" },
      })
    end)

    it("empty patterns", function()
      local w_dir = test_dir .. "/__resources__/web-workspaces/"
      local p_dirs = scanner.scan_workspace({ w_dir = w_dir, patterns = {} })
      assert.are.same(p_dirs, {})
    end)

    it("not exist dirs", function()
      local w_dir = test_dir .. "/__resources__/empty-dirs/"
      local p_dirs = scanner.scan_workspace({ w_dir = w_dir })
      assert.are.same(p_dirs, {})
    end)

    it("with __extra__", function()
      local w_dir = test_dir .. "/__resources__/web-workspaces/"
      local p_dirs = scanner.scan_workspace({ w_dir = w_dir, __extra__ = { a = 1 } })
      assert.are.same(p_dirs, {
        { dir = unify_slash(w_dir .. "cli/"), name = "cli", __extra__ = { a = 1 } },
        { dir = unify_slash(w_dir .. "ui-library/"), name = "ui-library", __extra__ = { a = 1 } },
      })
    end)
  end)

  describe("scan > ", function()
    it("only string (project dir)", function()
      local p_dir = test_dir .. "/__resources__/web-workspaces/"
      local result = scanner.scan(p_dir)
      assert.are.same(result, {
        { dir = unify_slash(p_dir), name = "web-workspaces", id = "/web-workspaces" },
      })
    end)

    describe("project object > ", function()
      it("only p_dir field", function()
        local p_dir = test_dir .. "/__resources__/web-workspaces/ui-library/"
        local result = scanner.scan({ p_dir = p_dir })
        assert.are.same(result, {
          { dir = unify_slash(p_dir), name = "ui-library", id = "/ui-library" },
        })
      end)

      it("p_dir and name fields", function()
        local p_dir = test_dir .. "/__resources__/web-workspaces/ui-library/"
        local result = scanner.scan({ p_dir = p_dir, name = "ui-library (open source)" })
        assert.are.same(result, {
          { dir = unify_slash(p_dir), name = "ui-library (open source)", id = "/ui-library (open source)" },
        })
      end)

      it("with __extra__", function()
        local p_dir = test_dir .. "/__resources__/web-workspaces/ui-library/"
        local result = scanner.scan({ p_dir = p_dir, __extra__ = { a = 1 } })
        assert.are.same(result, {
          { dir = unify_slash(p_dir), name = "ui-library", __extra__ = { a = 1 }, id = "/ui-library" },
        })
      end)
    end)

    describe("workspace object > ", function()
      it("only w_dir field", function()
        local w_dir = test_dir .. "/__resources__/web-workspaces/"
        local result = scanner.scan({ w_dir = w_dir })
        assert.are.same(result, {
          { dir = unify_slash(w_dir .. "cli/"), name = "cli", id = "/cli" },
          { dir = unify_slash(w_dir .. "ui-library/"), name = "ui-library", id = "/ui-library" },
        })
      end)

      it("w_dir and patterns fields", function()
        local w_dir = test_dir .. "/__resources__/web-workspaces/"
        local result = scanner.scan({ w_dir = w_dir, patterns = { "package.json" } })
        assert.are.same(result, {
          { dir = unify_slash(w_dir .. "cli/"), name = "cli", id = "/cli" },
        })
      end)

      it("w_dir and empty patterns fields", function()
        local w_dir = test_dir .. "/__resources__/web-workspaces/"
        local result = scanner.scan({ w_dir = w_dir, patterns = {} })
        assert.are.same(result, {})
      end)

      it('w_dir and `{ "*" }` patterns', function()
        local w_dir = test_dir .. "/__resources__/web-workspaces/"
        local result = scanner.scan({ w_dir = w_dir, patterns = { "*" } })
        assert.are.same(result, {
          { dir = unify_slash(w_dir .. "cli/"), name = "cli", id = "/cli" },
          { dir = unify_slash(w_dir .. "ui-library/"), name = "ui-library", id = "/ui-library" },
          { dir = unify_slash(w_dir .. "_temp/"), name = "_temp", id = "/_temp" },
        })
      end)

      it('w_dir and `"*"` patterns', function()
        local w_dir = test_dir .. "/__resources__/web-workspaces/"
        local result = scanner.scan({ w_dir = w_dir, patterns = { "*" } })
        assert.are.same(result, {
          { dir = unify_slash(w_dir .. "cli/"), name = "cli", id = "/cli" },
          { dir = unify_slash(w_dir .. "ui-library/"), name = "ui-library", id = "/ui-library" },
          { dir = unify_slash(w_dir .. "_temp/"), name = "_temp", id = "/_temp" },
        })
      end)

      it("w_dir and not exist dirs", function()
        local w_dir = test_dir .. "/__resources__/empty-dirs/"
        local result = scanner.scan({ w_dir = w_dir })
        assert.are.same(result, {})
      end)

      it("with __extra__", function()
        local w_dir = test_dir .. "/__resources__/web-workspaces/"
        local result = scanner.scan({ w_dir = w_dir, __extra__ = { a = 1 } })
        assert.are.same(result, {
          { dir = unify_slash(w_dir .. "cli/"), name = "cli", __extra__ = { a = 1 }, id = "/cli" },
          {
            dir = unify_slash(w_dir .. "ui-library/"),
            name = "ui-library",
            __extra__ = { a = 1 },
            id = "/ui-library",
          },
        })
      end)
    end)

    describe("with type > ", function()
      describe("simple > ", function()
        it("value is string (project dir)", function()
          local p_dir = test_dir .. "/__resources__/web-workspaces/"
          local result = scanner.scan({ web = p_dir })
          assert.are.same(result, {
            { name = "web", dir = unify_slash(p_dir), id = "/web" },
          })
        end)

        it("value is object (p_dir)", function()
          local p_dir = test_dir .. "/__resources__/web-workspaces/ui-library/"
          local result = scanner.scan({ web = { p_dir = p_dir } })
          assert.are.same(result, {
            { name = "web", dir = unify_slash(p_dir), id = "/web" },
          })

          -- with __extra__
          result = scanner.scan({ web = { p_dir = p_dir, __extra__ = { a = 1 } } })
          assert.are.same(result, {
            { name = "web", dir = unify_slash(p_dir), __extra__ = { a = 1 }, id = "/web" },
          })
        end)

        it("value is object (w_dir)", function()
          local w_dir = test_dir .. "/__resources__/web-workspaces/"
          local result = scanner.scan({ web = { w_dir = w_dir } })
          assert.are.same(result, {
            {
              type = "web",
              children = {
                { dir = unify_slash(w_dir .. "cli/"), name = "cli", id = "/web/cli" },
                { dir = unify_slash(w_dir .. "ui-library/"), name = "ui-library", id = "/web/ui-library" },
              },
              id = "/web",
            },
          })

          -- with __extra__
          result = scanner.scan({ web = { w_dir = w_dir, __extra__ = { a = 1 } } })
          assert.are.same(result, {
            {
              type = "web",
              children = {
                { dir = unify_slash(w_dir .. "cli/"), name = "cli", __extra__ = { a = 1 }, id = "/web/cli" },
                {
                  dir = unify_slash(w_dir .. "ui-library/"),
                  name = "ui-library",
                  __extra__ = { a = 1 },
                  id = "/web/ui-library",
                },
              },
              __extra__ = { a = 1 },
              id = "/web",
            },
          })
        end)

        it("value is object (w_dir and patterns)", function()
          local w_dir = test_dir .. "/__resources__/web-workspaces/"
          local result = scanner.scan({ web = { w_dir = w_dir, patterns = { "package.json" } } })
          assert.are.same(result, {
            {
              type = "web",
              children = { { dir = unify_slash(w_dir .. "cli/"), name = "cli", id = "/web/cli" } },
              id = "/web",
            },
          })

          -- with __extra__
          result = scanner.scan({ web = { w_dir = w_dir, patterns = { "package.json" }, __extra__ = { a = 1 } } })
          assert.are.same(result, {
            {
              type = "web",
              children = {
                { dir = unify_slash(w_dir .. "cli/"), name = "cli", __extra__ = { a = 1 }, id = "/web/cli" },
              },
              __extra__ = { a = 1 },
              id = "/web",
            },
          })
        end)

        it("value is object (w_dir and empty patterns)", function()
          local w_dir = test_dir .. "/__resources__/web-workspaces/"
          local result = scanner.scan({ web = { w_dir = w_dir, patterns = {} } })
          assert.are.same(result, { { type = "web", children = {}, id = "/web" } })

          -- with __extra__
          result = scanner.scan({ web = { w_dir = w_dir, patterns = {}, __extra__ = { a = 1 } } })
          assert.are.same(result, { { type = "web", children = {}, __extra__ = { a = 1 }, id = "/web" } })
        end)

        it('value is object (w_dir and `{ "*" }` patterns)', function()
          local w_dir = test_dir .. "/__resources__/web-workspaces/"
          local result = scanner.scan({ web = { w_dir = w_dir, patterns = { "*" } } })
          assert.are.same(result, {
            {
              type = "web",
              children = {
                { dir = unify_slash(w_dir .. "cli/"), name = "cli", id = "/web/cli" },
                { dir = unify_slash(w_dir .. "ui-library/"), name = "ui-library", id = "/web/ui-library" },
                { dir = unify_slash(w_dir .. "_temp/"), name = "_temp", id = "/web/_temp" },
              },
              id = "/web",
            },
          })

          -- with __extra__
          result = scanner.scan({ web = { w_dir = w_dir, patterns = { "*" }, __extra__ = { a = 1 } } })
          assert.are.same(result, {
            {
              type = "web",
              children = {
                { dir = unify_slash(w_dir .. "cli/"), name = "cli", __extra__ = { a = 1 }, id = "/web/cli" },
                {
                  dir = unify_slash(w_dir .. "ui-library/"),
                  name = "ui-library",
                  __extra__ = { a = 1 },
                  id = "/web/ui-library",
                },
                { dir = unify_slash(w_dir .. "_temp/"), name = "_temp", __extra__ = { a = 1 }, id = "/web/_temp" },
              },
              id = "/web",
              __extra__ = { a = 1 },
            },
          })
        end)

        it('value is object (w_dir and `"*"` patterns)', function()
          local w_dir = test_dir .. "/__resources__/web-workspaces/"
          local result = scanner.scan({ web = { w_dir = w_dir, patterns = "*" } })
          assert.are.same(result, {
            {
              type = "web",
              children = {
                { dir = unify_slash(w_dir .. "cli/"), name = "cli", id = "/web/cli" },
                { dir = unify_slash(w_dir .. "ui-library/"), name = "ui-library", id = "/web/ui-library" },
                { dir = unify_slash(w_dir .. "_temp/"), name = "_temp", id = "/web/_temp" },
              },
              id = "/web",
            },
          })

          -- with __extra__
          result = scanner.scan({ web = { w_dir = w_dir, patterns = "*", __extra__ = { a = 1 } } })
          assert.are.same(result, {
            {
              type = "web",
              children = {
                {
                  dir = unify_slash(w_dir .. "cli/"),
                  name = "cli",
                  id = "/web/cli",
                  __extra__ = { a = 1 },
                },
                {
                  dir = unify_slash(w_dir .. "ui-library/"),
                  name = "ui-library",
                  id = "/web/ui-library",
                  __extra__ = { a = 1 },
                },
                {
                  dir = unify_slash(w_dir .. "_temp/"),
                  name = "_temp",
                  id = "/web/_temp",
                  __extra__ = { a = 1 },
                },
              },
              id = "/web",
              __extra__ = { a = 1 },
            },
          })
        end)

        it("value is object (w_dir and not exist dirs)", function()
          local w_dir = test_dir .. "/__resources__/empty-dirs/"
          local result = scanner.scan({ web = { w_dir = w_dir } })
          assert.are.same(result, { { type = "web", children = {}, id = "/web" } })

          -- with __extra__
          result = scanner.scan({ web = { w_dir = w_dir, __extra__ = { a = 1 } } })
          assert.are.same(result, {
            { type = "web", children = {}, __extra__ = { a = 1 }, id = "/web" },
          })
        end)
      end)

      describe("complex > ", function()
        it("multiple type & with __extra__", function()
          local params = {
            web = {
              w_dir = test_dir .. "/__resources__/web-workspaces/",
              patterns = { "package.json" },
              __extra__ = { a = 1 },
            },
            web_temp = test_dir .. "/__resources__/web-workspaces/_temp/",
            __sub_dirs = {
              w_dir = test_dir .. "/__resources__/sub-dirs/",
              patterns = "*",
              __extra__ = { b = 2 },
            },
          }
          local result = scanner.scan(params)

          assert.are.same(result, {
            {
              type = "__sub_dirs",
              children = {
                {
                  dir = unify_slash(params.__sub_dirs.w_dir .. "a/"),
                  name = "a",
                  __extra__ = { b = 2 },
                  id = "/__sub_dirs/a",
                },
                {
                  dir = unify_slash(params.__sub_dirs.w_dir .. "b/"),
                  name = "b",
                  __extra__ = { b = 2 },
                  id = "/__sub_dirs/b",
                },
              },
              __extra__ = { b = 2 },
              id = "/__sub_dirs",
            },
            {
              type = "web",
              children = {
                {
                  dir = unify_slash(params.web.w_dir .. "cli/"),
                  name = "cli",
                  __extra__ = { a = 1 },
                  id = "/web/cli",
                },
              },
              __extra__ = { a = 1 },
              id = "/web",
            },
            { name = "web_temp", dir = unify_slash(params.web_temp), id = "/web_temp" },
          })
        end)
      end)
    end)
  end)
end)
