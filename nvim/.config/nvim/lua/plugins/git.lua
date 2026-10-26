return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- ============================================================================
    -- Gitsigns
    -- ============================================================================

    local status_ok, gitsigns = pcall(require, "gitsigns")
    if not status_ok then
      return
    end

    gitsigns.setup({
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "▁" },
        topdelete    = { text = "▔" },
        changedelete = { text = "▎" },
        untracked    = { text = "┆" },
      },

      -- signcolumn is already "yes" in settings.lua, so signs have somewhere to go
      signcolumn = true,
      numhl = false,
      linehl = false,
      word_diff = false,

      -- Virtual-text blame is off by default; <leader>hb toggles it.
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 300,
      },

      preview_config = { border = "single" },

      on_attach = function(bufnr)
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = "gitsigns: " .. desc })
        end

        -- Hunk navigation. Falls through to plain ]c/[c diff motions inside a
        -- real diff split, where gitsigns has nothing to say.
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end, "Next hunk")

        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end, "Prev hunk")

        -- Actions. <leader>h is otherwise unused; <leader>g is LSP navigation.
        map("n", "<leader>hs", gitsigns.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gitsigns.reset_hunk, "Reset hunk")
        map("v", "<leader>hs", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage selection")
        map("v", "<leader>hr", function()
          gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset selection")

        map("n", "<leader>hS", gitsigns.stage_buffer, "Stage buffer")
        map("n", "<leader>hR", gitsigns.reset_buffer, "Reset buffer")

        map("n", "<leader>hp", gitsigns.preview_hunk, "Preview hunk")
        map("n", "<leader>hi", gitsigns.preview_hunk_inline, "Preview hunk inline")
        map("n", "<leader>hd", gitsigns.diffthis, "Diff against index")
        map("n", "<leader>hD", function()
          gitsigns.diffthis("~")
        end, "Diff against last commit")

        map("n", "<leader>hb", gitsigns.toggle_current_line_blame, "Toggle line blame")
        map("n", "<leader>hB", function()
          gitsigns.blame_line({ full = true })
        end, "Blame line (full)")

        map("n", "<leader>hq", gitsigns.setqflist, "Hunks to quickfix")

        -- Hunk text object: dih / cih / vih
        map({ "o", "x" }, "ih", gitsigns.select_hunk, "Select hunk")
      end,
    })
  end,
}
