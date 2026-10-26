return {
  -- Claude Code IDE bridge. Claude runs in its own tmux pane, not inside
  -- nvim, so the terminal provider is "none": the plugin only runs the
  -- WebSocket server that Claude connects to (`/ide` in Claude, or
  -- `claude --ide`). Loaded at startup so the server is up before Claude
  -- looks for it.
  {
    "coder/claudecode.nvim",
    lazy = false,
    opts = {
      terminal = { provider = "none" },
    },
    keys = {
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",      desc = "Claude: add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>",       mode = "v", desc = "Claude: send selection" },
      { "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>",    desc = "Claude: add file", ft = { "NvimTree" } },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Claude: deny diff" },
    },
  },
}
