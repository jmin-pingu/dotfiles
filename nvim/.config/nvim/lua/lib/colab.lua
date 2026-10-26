-- ============================================================================
-- Colab GPU sessions
-- ============================================================================
-- Thin wrappers over the `colab` CLI (uv tool install google-colab-cli).
-- A .cu file runs on the session with <leader>ru (see lib/runners.lua).
--
--   <leader>Cn   start a GPU session (T4)    :ColabNew [GPU]
--   <leader>Cs   stop the session            :ColabStop
--   <leader>Ci   session status             :ColabStatus
--   <leader>Cc   shell on the VM             :ColabConsole

local function term(cmd)
  -- Same shape as the runners' output split: fresh buffer, q closes it.
  vim.cmd("botright 15new")
  vim.bo.bufhidden = "wipe"
  vim.fn.jobstart(cmd, { term = true })
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = 0, silent = true, desc = "Close output" })
end

local function colab(args)
  if vim.fn.executable("colab") == 0 then
    vim.notify('"colab" is not installed (uv tool install google-colab-cli)', vim.log.levels.ERROR)
    return
  end
  term(vim.list_extend({ "colab" }, args))
end

local M = {}

--- Compile and run the current .cu file on the session, using only
--- `colab exec`: one call writes the file on the VM (%%writefile), the next
--- compiles and runs it (!nvcc). Both are IPython magics in the VM's kernel.
function M.run_cu()
  local name = vim.fn.expand("%:t")
  local stem = vim.fn.expand("%:t:r")
  local build = ("!nvcc -arch=native -o %s %s && ./%s"):format(stem, name, stem)
  -- 8 '%' -> 4 after string.format -> 2 after printf: the `%%writefile` magic.
  local cmd = ("{ printf '%%%%%%%%writefile %s\\n'; cat %s; } | colab exec && echo %s | colab exec --timeout 300")
    :format(name, vim.fn.shellescape(vim.fn.expand("%:p")), vim.fn.shellescape(build))
  if vim.fn.executable("colab") == 0 then
    vim.notify('"colab" is not installed (uv tool install google-colab-cli)', vim.log.levels.ERROR)
    return
  end
  term(cmd)
end

vim.api.nvim_create_user_command("ColabNew", function(opts)
  colab({ "new", "--gpu", opts.args ~= "" and opts.args or "T4" })
end, { nargs = "?", desc = "Start a Colab GPU session (default T4)" })

vim.api.nvim_create_user_command("ColabStop", function() colab({ "stop" }) end,
  { desc = "Stop the Colab session" })
vim.api.nvim_create_user_command("ColabStatus", function() colab({ "status" }) end,
  { desc = "Show Colab session status" })
vim.api.nvim_create_user_command("ColabConsole", function()
  colab({ "console" })
  vim.cmd("startinsert")
end, { desc = "Shell on the Colab VM" })

vim.keymap.set("n", "<leader>Cn", "<cmd>ColabNew<cr>", { silent = true, desc = "Colab: new GPU session" })
vim.keymap.set("n", "<leader>Cs", "<cmd>ColabStop<cr>", { silent = true, desc = "Colab: stop session" })
vim.keymap.set("n", "<leader>Ci", "<cmd>ColabStatus<cr>", { silent = true, desc = "Colab: status" })
vim.keymap.set("n", "<leader>Cc", "<cmd>ColabConsole<cr>", { silent = true, desc = "Colab: console" })

return M
