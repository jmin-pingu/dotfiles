-- Find the Claude pane in this tmux window. Claude's process shows up as
-- "claude" or as its version number (e.g. "2.1.331").
local function claude_pane()
  local lines = vim.fn.systemlist({ "tmux", "list-panes", "-F", "#{pane_id}\t#{pane_current_command}" })
  for _, line in ipairs(lines) do
    local id, cmd = line:match("^(%S+)\t(.*)$")
    if id and id ~= vim.env.TMUX_PANE and (cmd == "claude" or cmd:match("^%d+%.%d+%.%d+$")) then
      return id
    end
  end
end

-- Ask Claude a question from nvim. Claude already sees your current
-- selection through the IDE connection, so nothing is sent first.
local function ask()
  local pane = claude_pane()
  if not pane then
    vim.notify("No Claude pane in this tmux window", vim.log.levels.WARN)
    return
  end
  vim.ui.input({ prompt = "Ask Claude: " }, function(q)
    if not q or q == "" then
      return
    end
    vim.fn.system({ "tmux", "send-keys", "-t", pane, "-l", q })
    vim.fn.system({ "tmux", "send-keys", "-t", pane, "Enter" })
  end)
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
      { "<leader>aj", ask, mode = { "n", "v" },        desc = "Claude: ask a question" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",      desc = "Claude: add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>",       mode = "v", desc = "Claude: send selection" },
      { "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>",    desc = "Claude: add file", ft = { "NvimTree" } },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Claude: deny diff" },
    },
  },
}
