-- ============================================================================
-- Keymaps
-- ============================================================================

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ============================================================================
-- NORMAL MODE
-- ============================================================================

-- Save file
map("n", "<leader>sf", ":w<CR>", opts)

-- Quick edit vimrc
map("n", "<leader>ev", ":vsplit ~/.config/nvim/init.lua<CR>", opts)

-- Cut, Copy, Paste (using system clipboard)
map("n", "<leader>xw", 'viw"*yviwD', opts)
map("n", "<leader>xl", 'V"*yVd', opts)
map("n", "<leader>xp", 'vip"*yvipd', opts)

map("n", "<leader>cw", 'viw"*y', opts)
map("n", "<leader>cl", 'V"*y', opts)
map("n", "<leader>cp", 'vip"*y', opts)

map("n", "<leader>v", '"*p', opts)

-- Window resizing
map("n", "<leader>rj", "<C-w>+", opts)
map("n", "<leader>rk", "<C-w>-", opts)
map("n", "<leader>rl", "<C-w><", opts)
map("n", "<leader>rh", "<C-w>>", opts)

-- Window navigation
map("n", "<leader>wl", "<C-w>l", opts)
map("n", "<leader>wj", "<C-w>j", opts)
map("n", "<leader>wk", "<C-w>k", opts)
map("n", "<leader>wh", "<C-w>h", opts)

-- Quick comments. Neovim 0.10+ ships gc/gcc natively, so vim-commentary is
-- gone; remap = true is required because gcc is itself a mapping.
map("n", "<leader>td", "iTODO: <esc>gccA", { remap = true, desc = "TODO comment" })
map("n", "<leader>nt", "iNOTE: <esc>gccA", { remap = true, desc = "NOTE comment" })

-- Source current file
map("n", "<leader>so", ":source %<CR>", opts)

-- Navigation
map("n", "J", "25j", opts)
map("n", "K", "25k", opts)
map("n", "H", "0", { desc = "Start of line" })
map("n", "L", "$", { desc = "End of line" })

-- Keep cursor centered during searches and page moves
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)

-- Quickfix navigation
map("n", "<leader>qn", ":cnext<CR>", opts)
map("n", "<leader>qp", ":cprev<CR>", opts)

-- Buffer navigation
map("n", "<leader>bn", ":bnext<CR>", opts)
map("n", "<leader>bp", ":bprev<CR>", opts)

-- ============================================================================
-- SUBSTITUTE
-- ============================================================================
-- Ported from ~/.vimrc, where these lived as Substitute()/SafeSubstitute()/
-- SubstituteCword()/SubstituteVisual() and never made it into the Lua config.

local function prompt(label)
  local ok, value = pcall(vim.fn.input, label .. ": ")
  return ok and value ~= "" and value or nil
end

--- :%s/<pattern>/<replacement>/<flags> with both sides prompted for.
local function substitute(flags)
  local pattern = prompt("regex")
  if not pattern then return end
  local replacement = prompt("sub")
  if not replacement then return end
  vim.cmd(("%%s/%s/%s/%s"):format(pattern, replacement, flags))
end

--- Substitute a literal string throughout the buffer. \V makes the pattern
--- "very nomagic", so a word containing . or * is matched literally.
local function substitute_literal(src, flags)
  local replacement = prompt("sub")
  if not replacement then return end
  vim.cmd(("%%s/\\V%s/%s/%s"):format(vim.fn.escape(src, "/\\"), replacement, flags))
end

map("n", "<leader>gsu", function() substitute("g") end, { desc = "Substitute (prompt regex)" })
map("n", "<leader>ssu", function() substitute("gc") end, { desc = "Substitute, confirm each" })
map("n", "<leader>wsu", function() substitute_literal(vim.fn.expand("<cword>"), "g") end,
  { desc = "Substitute word under cursor" })
map("x", "<leader>vsu", function()
  -- Grab the selection without disturbing the unnamed register.
  local save = vim.fn.getreg('"')
  vim.cmd('noautocmd normal! gvy')
  local selection = vim.fn.getreg('"')
  vim.fn.setreg('"', save)
  vim.schedule(function() substitute_literal(selection, "g") end)
end, { desc = "Substitute selection" })

-- ============================================================================
-- BUFFERS AND SPLITS
-- ============================================================================

map("n", "<leader>bb", ":ls<CR>:b<space>", { desc = "List buffers and jump" })
map("n", "<leader>bd", ":bd<CR>", { desc = "Delete buffer" })

-- Open the ALTERNATE buffer (#) in a split on the given side.
for key, cmd in pairs({
  bsh = "leftabove vsplit",
  bsl = "rightbelow vsplit",
  bsk = "belowright split",
  bsj = "aboveleft split",
}) do
  map("n", "<leader>" .. key, function()
    local alt = vim.fn.bufname("#")
    if alt == "" then
      vim.notify("no alternate buffer", vim.log.levels.WARN)
      return
    end
    vim.cmd(cmd .. " " .. vim.fn.fnameescape(alt))
  end, { desc = "Split alternate buffer" })
end

-- ============================================================================
-- TEXT EDITING
-- ============================================================================
-- NOTE: in .vimrc <leader>rw and <leader>p had a trailing `" comment` on the
-- same line. vimscript treats everything after the lhs as the rhs, so those
-- comments were silently part of the mapping. Fixed in the port.

map("n", "<leader>rw", '"_diwP', { desc = "Replace word with yanked text" })
map("x", "<leader>p", '"_dP', { desc = "Replace selection, keep register" })
map("n", "<leader>u", "viwoU<esc>e", { desc = "Uppercase word" })
map("x", "<leader>id", "=<esc>", { desc = "Re-indent selection" })
map("x", "<leader>cc", '"*y', { desc = "Copy selection to clipboard" })
map("x", "<leader>x", '"*y<esc>v`>d', { desc = "Cut selection to clipboard" })
map("n", "<leader>qna", "iQUESTION: <esc>", { desc = "QUESTION marker" })

--- Surround the visual selection with a prompted character.
map("x", "<leader>su", function()
  local ch = prompt("char")
  if not ch then return end
  -- \27 is a literal ESC byte. `\<esc>` is vimscript notation and is NOT a
  -- valid Lua escape - it is what broke this file on the first attempt.
  -- The leading ESC leaves visual mode, which is what sets the '< '> marks.
  local esc = "\27"
  vim.cmd(("noautocmd normal! %s`>a%s%s`<i%s%s"):format(esc, ch, esc, ch, esc))
end, { desc = "Surround selection with char" })

-- Fixed-pair surrounds, as in .vimrc.
for lhs, pair in pairs({
  ['""'] = { '"', '"' }, ["''"] = { "'", "'" }, ["``"] = { "`", "`" },
  ["(("] = { "(", ")" }, ["[["] = { "[", "]" }, ["{{"] = { "{", "}" },
  ["<<"] = { "<", ">" },
}) do
  map("x", lhs, ("<esc>`>a%s<esc>`<i%s<esc>"):format(pair[2], pair[1]),
    { desc = "Surround with " .. pair[1] .. pair[2] })
end

-- ============================================================================
-- TERMINAL
-- ============================================================================

map("n", "<leader>ot", ":terminal<CR>", { desc = "Open terminal" })
-- <leader>et is deliberately NOT a terminal-mode mapping. <leader> is Space,
-- so a t-mode mapping starting with it makes vim wait timeoutlen (500ms) on
-- EVERY space typed at the shell, to see whether "et" follows. That is the
-- one thing you cannot afford to make slow in a terminal.
--
-- It lives in normal mode instead, buffer-local to terminals (see the
-- TermOpen autocmd in core/autocmds.lua): <Esc><Esc> then <leader>et.
-- In normal mode a leader prefix costs nothing, because you are not typing
-- text into the program.

-- Source this config (was <leader>sv -> $MYVIMRC).
map("n", "<leader>sv", function()
  vim.cmd("source " .. vim.env.MYVIMRC)
  vim.notify("sourced " .. vim.env.MYVIMRC)
end, { desc = "Source init.lua" })

-- ============================================================================
-- INSERT MODE
-- ============================================================================

-- Exit insert mode
map("i", "jk", "<esc>", opts)
map("i", "kj", "<esc>", opts)

-- Navigation in insert mode
map("i", "<C-h>", "<Left>", opts)
map("i", "<C-j>", "<Down>", opts)
map("i", "<C-k>", "<Up>", opts)
map("i", "<C-l>", "<Right>", opts)

-- ============================================================================
-- VISUAL MODE
-- ============================================================================

-- Keep visual selection when indenting
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Navigation. J/K are the 25-line jumps here, matching normal and
-- operator-pending mode.
map("v", "J", "25j", opts)
map("v", "K", "25k", opts)
map("v", "H", "0", { desc = "Start of line" })
map("v", "L", "$", { desc = "End of line" })

-- Move the selection up and down. These used to be mapped to J/K, but the
-- 25j/25k mappings below them silently won, so they never worked.
map("v", "<leader>mj", ":m '>+1<CR>gv=gv", opts)
map("v", "<leader>mk", ":m '<-2<CR>gv=gv", opts)

-- ============================================================================
-- OPERATOR-PENDING MODE
-- ============================================================================

map("o", "J", "25j", opts)
map("o", "K", "25k", opts)
map("o", "H", "0", { desc = "Start of line" })
map("o", "L", "$", { desc = "End of line" })

-- ============================================================================
-- COMMAND MODE
-- ============================================================================

-- Navigation in command mode
map("c", "<C-h>", "<Left>", { noremap = true })
map("c", "<C-j>", "<Down>", { noremap = true })
map("c", "<C-k>", "<Up>", { noremap = true })
map("c", "<C-l>", "<Right>", { noremap = true })

-- Man page for the word under the cursor (was in coc.lua).
map("n", "<leader>man", function()
  vim.cmd("!" .. vim.bo.keywordprg .. " " .. vim.fn.expand("<cword>"))
end, opts)

-- ============================================================================
-- ARROW KEY DISCIPLINE
-- ============================================================================
-- coc.lua used to repurpose Up/Down for scrolling its float and nag otherwise.
-- The float scrolling is gone (hover floats take <C-f>/<C-b>), but keep the
-- nag - it is the same habit the mouse mappings below enforce.

map("n", "<Down>", function() vim.notify("Use j", vim.log.levels.WARN) end, opts)
map("n", "<Up>", function() vim.notify("Use k", vim.log.levels.WARN) end, opts)

-- ============================================================================
-- INSIDE LAST / INSIDE NEXT TEXT OBJECTS
-- ============================================================================
-- From .vimrc. `il(` is "inside last parens", `in(` is "inside next parens",
-- so `cin(` changes inside the next () without moving the cursor there first.
-- F searches backward for "last", f forward for "next".

for delim_open, delim_close in pairs({
  ["("] = ")", ["{"] = "}", ["["] = "]", ["<"] = ">",
  ['"'] = '"', ["'"] = "'", ["`"] = "`",
}) do
  local _ = delim_close
  map("o", "il" .. delim_open, (":<C-u>normal! F%svi%s<CR>"):format(delim_open, delim_open),
    { noremap = true, silent = true, desc = "Inside last " .. delim_open })
  map("o", "in" .. delim_open, (":<C-u>normal! f%svi%s<CR>"):format(delim_open, delim_open),
    { noremap = true, silent = true, desc = "Inside next " .. delim_open })
end

-- Operator-pending motion to the next `return`.
-- NOTE: this shadows the builtin operator-pending `b` (back-word), so `db`,
-- `cb` and `yb` no longer delete/change/yank backwards by a word. That was
-- already true in .vimrc; carried over deliberately.
map("o", "b", "/return<CR>", { noremap = true, silent = true, desc = "To next return" })

-- ============================================================================
-- TRAINING WHEELS
-- ============================================================================

map("n", "0", ':echoe "Use H"<CR>', { noremap = true, silent = true, desc = "Use H" })
map("n", "$", ':echoe "Use L"<CR>', { noremap = true, silent = true, desc = "Use L" })
