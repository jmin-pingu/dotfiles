-- :ClaudeCodeSendText needs Claude inside nvim, so these keys type into
-- Claude's tmux pane instead. tmux reports Claude's command as its version
-- (e.g. 2.1.312), which is how the pane is found.
local function claude_pane()
  local pane = vim.trim(vim.fn.system(
    [[tmux list-panes -F '#{pane_id} #{pane_current_command}' ]]
      .. [[| awk '$2 ~ /^[0-9]+\.[0-9]+\.[0-9]+$/ {print $1; exit}']]
  ))
  if pane == "" then
    vim.notify("No Claude pane in this tmux window", vim.log.levels.WARN)
    return nil
  end
  return pane
end

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
      {
        "<leader>am",
        function()
          vim.ui.input({ prompt = "Claude: " }, function(text)
            if not text or text == "" then
              return
            end
            local pane = claude_pane()
            if not pane then
              return
            end
            vim.fn.system({ "tmux", "send-keys", "-t", pane, "-l", text })
            vim.fn.system({ "tmux", "send-keys", "-t", pane, "Enter" })
          end)
        end,
        desc = "Claude: send message",
      },
      {
        -- Show the end of Claude's pane (the permission prompt) and accept
        -- only on confirm, so a stray keypress can't approve an unread command.
        "<leader>ay",
        function()
          local pane = claude_pane()
          if not pane then
            return
          end
          local screen = vim.fn.system({ "tmux", "capture-pane", "-p", "-t", pane, "-S", "-15" })
          if vim.fn.confirm(screen .. "\nAccept this?", "&Yes\n&No", 2) == 1 then
            vim.fn.system({ "tmux", "send-keys", "-t", pane, "Enter" })
          end
        end,
        desc = "Claude: accept prompt",
      },
      {
        "<leader>an",
        function()
          local pane = claude_pane()
          if pane then
            vim.fn.system({ "tmux", "send-keys", "-t", pane, "Escape" })
          end
        end,
        desc = "Claude: reject prompt",
      },
    },
  },
}
