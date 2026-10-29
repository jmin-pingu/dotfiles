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
      -- :ClaudeCodeSendText needs Claude inside nvim, so type into its tmux pane
      -- instead. tmux reports Claude's command as its version (e.g. 2.1.312).
      {
        "<leader>am",
        function()
          vim.ui.input({ prompt = "Claude: " }, function(text)
            if not text or text == "" then
              return
            end
            local pane = vim.trim(vim.fn.system(
              [[tmux list-panes -F '#{pane_id} #{pane_current_command}' ]]
                .. [[| awk '$2 ~ /^[0-9]+\.[0-9]+\.[0-9]+$/ {print $1; exit}']]
            ))
            if pane == "" then
              return vim.notify("No Claude pane in this tmux window", vim.log.levels.WARN)
            end
            vim.fn.system({ "tmux", "send-keys", "-t", pane, "-l", text })
            vim.fn.system({ "tmux", "send-keys", "-t", pane, "Enter" })
          end)
        end,
        desc = "Claude: send message",
      },
    },
  },
}
