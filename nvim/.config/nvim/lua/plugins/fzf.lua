-- ============================================================================
-- Fuzzy finder (fzf-lua)
-- ============================================================================
-- Extracted from init.lua. Exposes `opts` and `keys` as plain tables rather
-- than calling setup() itself: `keys` is lazy.nvim's lazy-loading metadata, so
-- it has to reach the plugin spec. Building these tables at startup is cheap
-- and does not load fzf-lua - lazy still binds stubs and loads on first press.
--
-- Uses the fzf binary installed via nix, and ripgrep for live_grep. Replaces
-- fzf.vim, which was installed but had no keymaps bound to it in either this
-- config or the old .vimrc.
return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "FzfLua",
  opts = {
      winopts = {
        height = 0.85,
        width = 0.85,
        preview = { layout = "flex", scrollbar = "float" },
      },
      files = { git_icons = true, file_icons = true },
      grep = { rg_glob = true },
  },

  keys = {
      -- files / buffers
      { "<leader>ff", "<cmd>FzfLua files<cr>",                 desc = "Find files" },
      { "<leader>fo", "<cmd>FzfLua oldfiles<cr>",              desc = "Recent files" },
      { "<leader>fb", "<cmd>FzfLua buffers<cr>",               desc = "Buffers" },
      { "<leader>fG", "<cmd>FzfLua git_files<cr>",             desc = "Git files" },
      -- searching
      { "<leader>fg", "<cmd>FzfLua live_grep<cr>",             desc = "Live grep" },
      { "<leader>fw", "<cmd>FzfLua grep_cword<cr>",            desc = "Grep word under cursor" },
      { "<leader>f/", "<cmd>FzfLua blines<cr>",                desc = "Search in buffer" },
      -- lsp pickers (these beat the built-in quickfix versions)
      { "<leader>fr", "<cmd>FzfLua lsp_references<cr>",        desc = "LSP references" },
      { "<leader>fd", "<cmd>FzfLua lsp_definitions<cr>",       desc = "LSP definitions" },
      { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<cr>",  desc = "Document symbols" },
      { "<leader>fS", "<cmd>FzfLua lsp_live_workspace_symbols<cr>", desc = "Workspace symbols" },
      { "<leader>fa", "<cmd>FzfLua lsp_code_actions<cr>",      desc = "Code actions" },
      { "<leader>fx", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Diagnostics" },
      -- misc
      { "<leader>fh", "<cmd>FzfLua helptags<cr>",              desc = "Help tags" },
      { "<leader>fk", "<cmd>FzfLua keymaps<cr>",               desc = "Keymaps" },
      { "<leader>fc", "<cmd>FzfLua commands<cr>",              desc = "Commands" },
      { "<leader>fp", "<cmd>FzfLua resume<cr>",                desc = "Resume last picker" },
  },
}
