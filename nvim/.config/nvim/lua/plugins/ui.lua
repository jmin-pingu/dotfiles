return {
  {
    -- Status line + buffer tabline (replaces vim-airline, 336 vimscript files)
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    config = function()
      -- ============================================================================
      -- Statusline (lualine)
      -- ============================================================================
      -- Replaces vim-airline. The section layout mirrors what airline showed:
      --   mode | branch, diff, diagnostics | filename | filetype, encoding | pos
      -- including airline's "LN:" / "CN:" labels for line and column.

      local status_ok, lualine = pcall(require, "lualine")
      if not status_ok then
        return
      end

      lualine.setup({
        options = {
          theme = "auto", -- follows the active colorscheme
          icons_enabled = true,
          -- airline's powerline separators were "" / ""; keep the same shapes.
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          globalstatus = false, -- one statusline per window, as airline had
          disabled_filetypes = { statusline = { "dashboard", "NvimTree" } },
        },

        sections = {
          lualine_a = { "mode" },
          lualine_b = {
            "branch",
            { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
            {
              "diagnostics",
              sources = { "nvim_diagnostic" },
              symbols = { error = "✗ ", warn = "⚠ ", info = "ℹ ", hint = "➜ " },
            },
          },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = {
            -- Metals status, e.g. "Compiling common". Empty outside Scala.
            function() return vim.g.metals_status or "" end,
            -- Which LSP servers are attached to this buffer.
            {
              function()
                local names = {}
                for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
                  names[#names + 1] = c.name
                end
                return #names > 0 and table.concat(names, ",") or ""
              end,
              icon = "",
            },
            "filetype",
            "encoding",
            { "fileformat", symbols = { unix = "[unix]", dos = "[dos]", mac = "[mac]" } },
          },
          lualine_y = { "progress" },
          lualine_z = {
            { "location", fmt = function(str)
                local line, col = str:match("(%d+):(%d+)")
                if not line then
                  return str
                end
                return ("LN:%s/%d CN:%s"):format(line, vim.api.nvim_buf_line_count(0), col)
              end },
          },
        },

        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },

        -- airline#extensions#tabline#enabled = 1
        --
        -- theme = "auto" derives the tabline colours from the colorscheme, and under
        -- "minimalist" it resolved active and inactive buffers to the SAME thing
        -- (fg #8a8a8a on bg #3a3a3a, both bold) - a buffer list with no way to tell
        -- which buffer you are in. buffers_color overrides that explicitly: the
        -- active buffer is an inverted pill in the scheme's accent, the rest recede.
        tabline = {
          lualine_a = {
            {
              "buffers",
              mode = 2, -- name + buffer number, so :b <n> is readable off the bar
              symbols = { alternate_file = "" },
              buffers_color = {
                active   = { fg = "#101010", bg = "#aca1cf", gui = "bold" },
                inactive = { fg = "#6c6c6c", bg = "#1c1c1c" },
              },
            },
          },
          lualine_z = { "tabs" },
        },

        extensions = { "nvim-tree", "lazy", "quickfix" },
      })
    end,
  },

  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- ============================================================================
      -- Dashboard (start screen)
      -- ============================================================================
      -- Shown when nvim is launched with no file arguments. The nvim-tree
      -- auto-open in core/autocmds.lua used to claim that same case; it now only
      -- fires for `nvim <directory>`, so the two no longer fight over VimEnter.

      local status_ok, dashboard = pcall(require, "dashboard")
      if not status_ok then
        return
      end

      dashboard.setup({
        theme = "doom",
        config = {
          -- Block letters, 5 rows. Swap the word by regenerating these lines -
          -- there is nothing structural here, just strings.
          header = {
            "",
            "",
            "█   █  █████  █   █   ████   ███ ",
            "█   █    █    ██  █  █      █   █",
            "█ █ █    █    █ █ █  █  ██  █   █",
            "██ ██    █    █  ██  █   █  █   █",
            "█   █  █████  █   █   ████   ███ ",
            "",
            "",
          },

          center = {
            {
              icon = "  ",
              desc = "Find file",
              key = "f",
              action = "FzfLua files",
            },
            {
              icon = "  ",
              desc = "Recent files",
              key = "r",
              action = "FzfLua oldfiles",
            },
            {
              icon = "  ",
              desc = "Live grep",
              key = "g",
              action = "FzfLua live_grep",
            },
            {
              icon = "  ",
              desc = "File tree",
              key = "e",
              action = "NvimTreeToggle",
            },
            {
              icon = "  ",
              desc = "Config",
              key = "c",
              action = "edit ~/.config/nvim/init.lua",
            },
            {
              icon = "   ",
              desc = "Plugins",
              key = "l",
              action = "Lazy",
            },
            {
              icon = "  ",
              desc = "Quit",
              key = "q",
              action = "qa",
            },
          },

          footer = function()
            local stats = require("lazy").stats()
            return {
              "",
              ("󰐋  %d plugins in %.1fms"):format(stats.count, stats.startuptime),
            }
          end,
        },
      })
    end,
  },

  -- Inline colour previews for #rrggbb etc. (replaces ap/vim-css-color)
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = { user_default_options = { names = false, css = true, tailwind = false } },
  },

  -- Colour schemes
  "rafi/awesome-vim-colorschemes",
  "jaredgorski/Mies.vim",
}
