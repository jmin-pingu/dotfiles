return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  dependencies = { { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" } },
  build = ":TSUpdate",
  config = function()
    -- ============================================================================
    -- Treesitter Configuration
    -- ============================================================================

    local status_ok, treesitter_configs = pcall(require, "nvim-treesitter.configs")
    if not status_ok then
      return
    end

    -- A few grammars (latex among them) ship as grammar definitions rather than
    -- pre-generated C, so nvim-treesitter must run the tree-sitter CLI to build
    -- them. Listing one without the CLI present throws during startup, so they
    -- are only requested when the CLI is actually available.
    local has_cli = vim.fn.executable("tree-sitter") == 1

    local needs_cli = { "latex" }

    treesitter_configs.setup({
      -- A list of parser names, or "all"
      ensure_installed = {
        "c",
        "cuda",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "go",
        "python",
        "javascript",
        "typescript",
        "html",
        "css",
        "json",
        "yaml",
        "bash",
        "markdown",
        "markdown_inline",
        "rust",
        "scala",
        "tsx",
        "toml",
        "terraform",
        "dockerfile",
        "java",
        "erlang",
        "haskell",
        -- Not a language: every parser above injects this one into its comment
        -- nodes, and it is what recognises TODO: / NOTE: / FIXME: / WARNING: /
        -- BUG: etc. and tags them @comment.todo, @comment.note, @comment.error,
        -- @comment.warning. Without it those words are plain Comment.
        "comment",
        unpack(has_cli and needs_cli or {}),
      },

      -- Install parsers synchronously (only applied to `ensure_installed`)
      sync_install = false,

      -- Automatically install missing parsers when entering a buffer.
      -- MUST be gated on the tree-sitter CLI existing: without it, opening a file
      -- whose parser is missing throws inside the FileType autocmd chain, and
      -- that abort takes out every later FileType handler - including the one
      -- vim.lsp.enable() uses to attach servers. A missing CLI silently cost us
      -- texlab on .tex files. Flips to true on its own once the CLI is installed.
      auto_install = vim.fn.executable("tree-sitter") == 1,

      -- List of parsers to ignore installing
      ignore_install = has_cli and {} or needs_cli,

      highlight = {
        enable = true,
        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false,
      },

      indent = {
        enable = true,
      },

      -- Text objects. coc supplied if/af/ic/ac before; treesitter does it now,
      -- and it works without a language server running.
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["if"] = "@function.inner",
            ["af"] = "@function.outer",
            ["ic"] = "@class.inner",
            ["ac"] = "@class.outer",
            ["ia"] = "@parameter.inner",
            ["aa"] = "@parameter.outer",
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = { ["]f"] = "@function.outer", ["]]"] = "@class.outer" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[["] = "@class.outer" },
        },
      },
    })

    -- nvim-treesitter-textobjects installs its `move` keymaps in normal, visual and
    -- operator-pending modes, with no way to pick modes per key. That makes the
    -- buffer-local `[[` shadow the global visual-mode `[]` surround, which came
    -- over from .vimrc - buffer-local always wins over global.
    --
    -- Class navigation is worth keeping where you actually navigate (normal and
    -- operator-pending, so `[[` and `d]]` still work), but in visual mode the
    -- surround is the one we want. Drop just the visual entries once the plugin
    -- has attached to the buffer.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("ts_move_visual_fix", { clear = true }),
      callback = function(args)
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(args.buf) then return end
          for _, mode in ipairs({ "v", "x" }) do
            for _, lhs in ipairs({ "[[", "]]" }) do
              pcall(vim.keymap.del, mode, lhs, { buffer = args.buf })
            end
          end
        end)
      end,
    })
  end,
}
