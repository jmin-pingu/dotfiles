return {
  -- Diagnostics / quickfix / symbols list
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Trouble",
    opts = {},
    keys = {
      -- <leader>x is taken by the cut-to-clipboard maps, so trouble lives
      -- under <leader>t (only <leader>td, the TODO comment, was there).
      { "<leader>tt", "<cmd>Trouble diagnostics toggle<cr>",                        desc = "Trouble: workspace diagnostics" },
      { "<leader>tb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",           desc = "Trouble: buffer diagnostics" },
      { "<leader>ts", "<cmd>Trouble symbols toggle focus=false<cr>",                desc = "Trouble: symbols" },
      { "<leader>tl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "Trouble: LSP refs/defs" },
      { "<leader>tq", "<cmd>Trouble qflist toggle<cr>",                             desc = "Trouble: quickfix" },
      { "<leader>tL", "<cmd>Trouble loclist toggle<cr>",                            desc = "Trouble: loclist" },
    },
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- Lazy-loading on `keys` alone registers the mapping but NOT the user
    -- commands, so :NvimTreeToggle did not exist until <leader>dir had been
    -- pressed once - which broke the dashboard's "File tree" entry. Listing
    -- the commands here makes lazy.nvim create loader stubs for them.
    cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeClose", "NvimTreeFocus", "NvimTreeFindFile" },
    keys = { { "<leader>dir", "<cmd>NvimTreeToggle<cr>", desc = "Toggle NvimTree" } },
    config = function()
      require("nvim-tree").setup({
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")
          -- keep every default mapping, then layer our own on top
          api.config.mappings.default_on_attach(bufnr)
          local function opts(desc)
            return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
          end
          vim.keymap.set("n", "i", api.node.open.edit, opts("Open"))
        end,
        renderer = {
          icons = {
            show = { git = true, file = true, folder = true, folder_arrow = true },
            glyphs = {
              folder = { arrow_closed = "⏵", arrow_open = "⏷" },
              git = { unstaged = "~", staged = "+", unmerged = "!", renamed = "→",
                      untracked = "?", deleted = "-", ignored = "◌" },
            },
          },
        },
      })
    end,
  },

  {
    -- Linters that are not language servers (replaces coc-markdownlint)
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- ============================================================================
      -- Linters (nvim-lint)
      -- ============================================================================
      -- Some tools are linters, not language servers - they have no LSP interface,
      -- so vim.lsp.enable cannot start them. nvim-lint shells out to the binary and
      -- pushes the results into vim.diagnostic, the same pipeline the LSP feeds.
      -- That is why the signs and virtual text configured in plugins/lsp.lua apply
      -- here too, with no extra work.
      --
      -- This replaces coc-markdownlint.

      local status_ok, lint = pcall(require, "lint")
      if not status_ok then
        return
      end

      lint.linters_by_ft = {
        markdown = { "markdownlint-cli2" },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
        callback = function()
          local names = lint.linters_by_ft[vim.bo.filetype]
          if not names then
            return
          end
          -- Skip silently when the binary is not installed yet (e.g. before
          -- darwin-rebuild), rather than erroring on every save.
          for _, name in ipairs(names) do
            local linter = lint.linters[name]
            local cmd = type(linter) == "table" and linter.cmd or name
            if vim.fn.executable(cmd) == 0 then
              return
            end
          end
          lint.try_lint()
        end,
      })

      vim.api.nvim_create_user_command("Lint", function()
        lint.try_lint()
      end, { desc = "Run linters for this buffer" })
    end,
  },
}
