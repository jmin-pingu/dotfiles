-- ============================================================================
-- Completion (blink.cmp)
-- ============================================================================
-- Extracted from init.lua, which should list WHICH plugins exist rather than
-- how each one is configured. Returns the opts table; the spec in init.lua
-- passes it straight to blink.
--
-- Replaces coc's popup. version="*" on the spec pulls a prebuilt fuzzy binary.
return {
  "saghen/blink.cmp",
  version = "*", -- prebuilt fuzzy binary
  event = "InsertEnter",
  -- colorful-menu re-parses each item with treesitter so the popup is coloured
  -- like the buffer. Must load before blink draws, hence a dependency.
  dependencies = { { "xzbdmw/colorful-menu.nvim", opts = {} } },
  opts = {
      keymap = {
        preset = "none",
        -- Mirrors the coc bindings: Tab/S-Tab cycle, CR accepts.
        --
        -- "select_next" only fires when the menu is already open, so on its
        -- own Tab could never OPEN completion - coc used to, via coc#refresh().
        -- The function below restores that: after a non-blank character Tab
        -- shows the menu, after whitespace it indents (spaces, per expandtab).
        ["<Tab>"] = {
          "select_next",
          "snippet_forward",
          function(cmp)
            local col = vim.fn.col(".") - 1
            if col > 0 and vim.fn.getline("."):sub(col, col):match("%S") then
              return cmp.show()
            end
          end,
          "fallback",
        },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<CR>"]    = { "accept", "fallback" },
        ["<C-e>"]   = { "hide", "fallback" },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
      },
      completion = {
        list = { selection = { preselect = false, auto_insert = true } },
        menu = {
          border = "single",
          -- Upstream documents this as a config = function() calling setup();
          -- expressed here as opts to match the rest of this file. Splitting
          -- label into text + highlight is what lets colorful-menu return
          -- per-range highlights instead of a single group for the whole item.
          draw = {
            columns = { { "kind_icon" }, { "label", gap = 1 } },
            components = {
              label = {
                text = function(ctx)
                  return require("colorful-menu").blink_components_text(ctx)
                end,
                highlight = function(ctx)
                  return require("colorful-menu").blink_components_highlight(ctx)
                end,
              },
            },
          },
        },
        documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = "single" } },
      },
      signature = { enabled = true, window = { border = "single" } },
      sources = { default = { "lsp", "path", "buffer" } },
      fuzzy = { implementation = "prefer_rust_with_warning" },
  },
}
