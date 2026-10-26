vim.bo.textwidth = 80

if vim.fn.executable("prettier") == 1 then
  vim.bo.formatprg = "prettier --parser markdown --prose-wrap always --print-width 80"
end

vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.colorcolumn = "81"

vim.api.nvim_create_autocmd("BufWinLeave", {
  buffer = 0,
  group = vim.api.nvim_create_augroup("markdown_window_opts_" .. vim.api.nvim_get_current_buf(), { clear = true }),
  callback = function()
    vim.wo.wrap = false
    vim.wo.linebreak = false
    vim.wo.colorcolumn = ""
  end,
})

-- <leader>cf: format, same key as LSP buffers. Whole file in normal mode,
-- the selection in visual mode.
vim.keymap.set("n", "<leader>cf", function()
  local view = vim.fn.winsaveview()
  vim.cmd("silent keepjumps normal! gggqG")
  vim.fn.winrestview(view)
end, { buffer = 0, silent = true, desc = "markdown: Format file" })
vim.keymap.set("x", "<leader>cf", "gq", { buffer = 0, silent = true, desc = "markdown: Format selection" })
