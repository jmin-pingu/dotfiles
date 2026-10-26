-- ============================================================================
-- Autocommands
-- ============================================================================

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Open NvimTree when nvim is started on a DIRECTORY (`nvim .`).
vim.api.nvim_create_autocmd("VimEnter", {
  group = augroup("nvimtree_open_dir", { clear = true }),
  callback = function(data)
    if vim.fn.isdirectory(data.file) ~= 1 then
      return
    end
    vim.cmd.cd(data.file)
    require("nvim-tree.api").tree.open()
  end,
})

-- Auto-clear search highlight
local hlsearch_ns = vim.api.nvim_create_namespace("auto_hlsearch")
vim.on_key(function(char)
  if vim.fn.mode() ~= "n" then
    return
  end
  local keep = vim.tbl_contains(
    { "<CR>", "n", "N", "*", "#", "?", "/" },
    vim.fn.keytrans(char)
  )
  if vim.opt.hlsearch:get() ~= keep then
    vim.opt.hlsearch = keep
  end
end, hlsearch_ns)

-- Terminal buffers in insert mode
autocmd("TermOpen", {
  group = augroup("terminal_ui", { clear = true }),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.spell = false
    vim.opt_local.cursorline = false

    -- Two things make a :terminal sluggish under heavy output, which
    -- <leader>ru and <leader>rp produce constantly:
    --   1. matchparen runs on CursorMoved AND TextChanged.
    --   2. scrollback defaults to 10000 lines, all retained and redrawn.
    vim.b.matchparen_timeout = 1
    vim.b.matchparen_insert_timeout = 1
    vim.opt_local.scrollback = 2000

    -- Close the terminal with <leader>et, as in .vimrc
    vim.keymap.set("n", "<leader>et", "<cmd>q!<cr>",
      { buffer = true, desc = "Close terminal" })

    vim.cmd("startinsert")
  end,
})

-- Leave terminal-insert mode with double-Esc.
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Terminal: to normal mode" })

-- ============================================================================
-- FILETYPE DETECTION
-- ============================================================================

autocmd({ "BufNewFile", "BufRead" }, {
  pattern = "*.tutor",
  callback = function()
    vim.bo.filetype = "tutor"
  end,
})

autocmd({ "BufNewFile", "BufRead" }, {
  pattern = "*.templ",
  callback = function()
    vim.bo.filetype = "templ"
  end,
})

-- Docker compose filetype detection
autocmd("FileType", {
  pattern = "yaml",
  callback = function()
    local filename = vim.fn.bufname("%")
    if filename:match("docker%-compose%.ya?ml") or filename:match("compose%.ya?ml") then
      vim.bo.filetype = "yaml.docker-compose"
    end
  end,
})

-- ============================================================================
-- COLOR SCHEME CUSTOMIZATIONS
-- ============================================================================
-- Ported verbatim from ~/.vimrc's ColorSchemePre/ColorScheme autocmds, but as
-- data rather than six near-identical blocks. Values are cterm indices 0-255;
-- colors.hi() emits the matching gui hex alongside each one, so these render
-- the same whether termguicolors is on or off.
--
-- To add a scheme: one more entry here. To tweak one: change a number.

local colors = require("lib.colors")

local theme_overrides = {
  ["twilight256"] = {
    CursorLine   = { bg = 0 },
    Visual       = { fg = 7 },
    CursorLineNr = { fg = 4, bg = 8 },
    Search       = { fg = 0, bg = 245 },
    CurSearch    = { fg = 0, bg = 3 },
    Conceal      = { fg = 9, bg = "none", attr = "underline" },
    LspInlayHint = { fg = 181, bg = "none" },
    NormalFloat  = { bg = 232 },
  },
  ["minimalist"] = {
    -- 236 (#303030) read as a bright band on vesper's #101010 background;
    -- 234 (#1c1c1c) is a gentler lift. CursorLineSign/Fold carry the same bg
    -- so the sign and fold columns do not punch a gap in the band.
    CursorLine     = { bg = 234 },
    CursorLineNr   = { fg = 4, bg = 234 },
    CursorLineSign = { bg = 234 },
    CursorLineFold = { bg = 234 },
    -- The scheme gave Cursor a solid light bg, and the terminal paints that
    -- block without honouring the foreground, so the character underneath
    -- vanished. Clearing both and inverting instead makes the cursor a hole
    -- in the text: the glyph stays readable whatever colour it happens to be.
    Cursor       = { fg = "none", bg = "none", attr = "reverse" },
    Visual       = { fg = 7 },
    Search       = { fg = 12, bg = 15, attr = "standout" },
    IncSearch    = { fg = 12, bg = 15, attr = "standout" },
    CurSearch    = { fg = 0, bg = 3 },
    NonText      = { fg = "none", bg = "none" },
    Conceal      = { fg = 9, attr = "underline" },
    LspInlayHint = { fg = 181, bg = "none" },
    NormalFloat  = { bg = 232 },

    -- Completion popup. PmenuSel shipped as #5f5f5f, a mid grey, and the
    -- "from Prelude" descriptions inherit a dim foreground - dim grey on mid
    -- grey is unreadable. The fix is to darken the SELECTION rather than
    -- brighten the description: a dark selected row keeps secondary text
    -- legible both on and off the highlight.
    Pmenu                    = { fg = 250, bg = 233 },
    PmenuSel                 = { fg = 255, bg = 237 },
    PmenuThumb               = { bg = 240 },
    -- 247 (#9e9e9e) clears ~4.4:1 on the selected row and ~7:1 off it.
    BlinkCmpLabelDescription = { fg = 247 },
    BlinkCmpLabelDetail      = { fg = 245 },
    BlinkCmpLabelMatch       = { fg = 4, attr = "bold" },
  },
  ["rdark-terminal2"] = {
    CursorLine   = { bg = 0 },
    Visual       = { fg = 15, bg = 0 },
    CursorLineNr = { fg = 4, bg = 0 },
    Conceal      = { fg = 9, bg = "none", attr = "underline" },
    IncSearch    = { fg = 0 },
    Search       = { fg = 0, bg = 7 },
    CurSearch    = { fg = 0, bg = 3 },
    LspInlayHint = { fg = 181, bg = "none" },
    NormalFloat  = { bg = 232 },
  },
  ["habamax"] = {
    Visual       = { fg = 249, bg = 233 },
    CursorLineNr = { fg = 5, bg = 233 },
    CursorLine   = { bg = 233 },
    Search       = { fg = 215, bg = 234 },
    CurSearch    = { fg = 0, bg = 5 },
    Conceal      = { fg = 8, bg = "none", attr = "underline" },
    LspInlayHint = { fg = 102, bg = "none" },
    NormalFloat  = { bg = 232 },
  },
  ["nord"] = {
    Visual       = { fg = 249, bg = 233 },
    CursorLineNr = { fg = 4, bg = 233 },
    CursorLine   = { bg = 233 },
    LspInlayHint = { fg = 103, bg = "none" },
    NormalFloat  = { bg = 232 },
  },
  ["mies"] = {
    -- mies ships a light variant; force dark as before.
    __background = "dark",
    Visual       = { fg = 249, bg = 236 },
    CursorLineNr = { bg = 236 },
    CursorLine   = { bg = 236 },
    LspInlayHint = { fg = 102, bg = "none" },
    NormalFloat  = { bg = 232 },
    Search       = { fg = 7, bg = 238 },
    CurSearch    = { fg = 7, bg = 238 },
    IncSearch    = { fg = 7, bg = 238 },
  },
}

local theme_group = augroup("theme_overrides", { clear = true })
autocmd({ "ColorSchemePre", "ColorScheme" }, {
  pattern = vim.tbl_keys(theme_overrides),
  group = theme_group,
  callback = function(args)
    local rules = theme_overrides[args.match]
    if not rules then
      return
    end
    if rules.__background then
      vim.o.background = rules.__background
    end
    for group, spec in pairs(rules) do
      if group ~= "__background" then
        colors.hi(group, spec)
      end
    end
  end,
})

-- ============================================================================
-- LSP REFERENCE HIGHLIGHT
-- ============================================================================
-- The per-buffer CursorHold autocmd lives in plugins/lsp.lua, gated on the
-- server actually supporting textDocument/documentHighlight. Only the
-- highlight groups are set here.
--
-- 'formatexpr' is no longer set by hand: on LspAttach Neovim 0.11 points it at
-- vim.lsp.formatexpr(), though only for servers advertising rangeFormatting.
--
-- Two things this block gets wrong if written naively, both of which bit us:
--   1. cterm=Bold,Underline alone is inert now that termguicolors is on. The
--      gui= half has to be set too (same trap as the theme rules).
--   2. Loading a colorscheme clears every highlight group, and colorscheme.lua
--      is required AFTER this file - so setting these once at load time got
--      them wiped immediately. They have to be re-applied on ColorScheme.

local function set_lsp_reference_highlights()
  for _, group in ipairs({ "LspReferenceText", "LspReferenceRead", "LspReferenceWrite" }) do
    vim.api.nvim_set_hl(0, group, {
      bold = true,
      underline = true,
      cterm = { bold = true, underline = true },
    })
  end
end

-- Servers that send semantic tokens (zls, rust-analyzer, clangd, ...) tag
-- every comment as @lsp.type.comment, which links to Comment and is drawn at
-- priority 125 - above all treesitter captures at 100. That repaints the
-- whole comment grey OVER the @comment.todo / @comment.note highlights the
-- injected `comment` parser produced, so TODO: and NOTE: vanish in exactly
-- the languages with the best LSPs. Clearing the group makes the LSP comment
-- token draw nothing; treesitter already highlights comments perfectly well.
local function clear_lsp_comment_token()
  vim.api.nvim_set_hl(0, "@lsp.type.comment", {})
end

autocmd("ColorScheme", {
  group = augroup("lsp_reference_highlights", { clear = true }),
  pattern = "*",
  callback = function()
    set_lsp_reference_highlights()
    clear_lsp_comment_token()
  end,
})

set_lsp_reference_highlights()
clear_lsp_comment_token()
