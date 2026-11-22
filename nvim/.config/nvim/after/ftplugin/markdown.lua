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

-- <leader>mp: save, then render to a temp PDF (LaTeX math included) and open
-- it. Runs in the background; uses ~/bin/mdpdf.
vim.keymap.set("n", "<leader>mp", function()
  vim.cmd("silent update")
  local file = vim.api.nvim_buf_get_name(0)
  vim.notify("mdpdf: rendering " .. vim.fn.fnamemodify(file, ":t") .. "...")
  vim.system({ vim.fn.expand("~/bin/mdpdf"), file }, { text = true }, function(res)
    vim.schedule(function()
      if res.code == 0 then
        vim.notify("mdpdf: done")
      else
        vim.notify("mdpdf failed:\n" .. (res.stderr or ""), vim.log.levels.ERROR)
      end
    end)
  end)
end, { buffer = 0, desc = "markdown: Render to PDF" })
