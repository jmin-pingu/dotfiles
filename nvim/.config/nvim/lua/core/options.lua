-- ============================================================================
-- Core Settings
-- ============================================================================

local opt = vim.opt
local g = vim.g

-- Display settings
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.wrap = false
opt.scrolloff = 8
opt.signcolumn = "yes"

-- Search settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
-- Tab inserts spaces. Filetypes that need real tabs (go, make) set
-- noexpandtab in their stock ftplugin, which runs after this and wins.
opt.expandtab = true

-- Split behavior
opt.splitbelow = true
opt.splitright = true

-- File handling
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undo"

-- Cursor shape. Neovim's default is "i-ci-ve:ver25", a 25%-width vertical
-- bar in insert mode; this keeps the block in every mode instead. Ghostty's
-- own `cursor-style = block` does not apply, because Neovim emits its own
-- cursor-shape escapes from this option and overrides the terminal.
opt.guicursor = "n-v-c-sm:block,i-ci-ve:block,r-cr:block,o:block,"
  .. "a:blinkon500-blinkoff500-Cursor/lCursor,t:block-blinkon500-blinkoff500-TermCursor"

-- Performance
opt.updatetime = 300
opt.timeoutlen = 500

-- Colors
-- 24-bit colour. The theme rules in core/autocmds.lua are written as cterm
-- indices and lib/colors.lua emits the matching gui hex for each, so both
-- modes render identically - set this back to false and nothing breaks.
opt.termguicolors = true
opt.background = "dark"

-- Miscellaneous
opt.mouse = ""  -- Disable mouse (based on your mouse mappings)
opt.clipboard = "unnamedplus"  -- Use system clipboard
opt.completeopt = "menu,menuone,noselect"
opt.laststatus = 2

-- Always draw the tabline. lualine puts the BUFFER list there (its port of
-- airline#extensions#tabline#enabled), but the nvim default of 1 only shows
-- the tabline once a second TAB exists - and this is a buffer-based workflow,
-- so it never appeared. 2 = always.
opt.showtabline = 2

-- Folding
opt.foldmethod = "marker"
opt.foldmarker = "{{{,}}}"

-- Status line (airline will override this)
opt.showmode = false

-- OCaml/opam settings.
-- This used to run `opam var share` via vim.fn.system() on EVERY startup -
-- a subprocess spawn on every launch, and it fired even when opam was
-- missing, because a failed system() returns non-empty error text. Now it is
-- deferred to the first OCaml buffer and guarded on opam existing.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("opam_rtp", { clear = true }),
  pattern = { "ocaml", "ocamlinterface", "dune" },
  once = true,
  callback = function()
    if vim.fn.executable("opam") == 0 then
      return
    end
    local share = vim.trim(vim.fn.system("opam var share"))
    if vim.v.shell_error ~= 0 or share == "" then
      return
    end
    local ocp = share .. "/ocp-indent/vim"
    if vim.fn.isdirectory(ocp) == 1 then
      opt.rtp:prepend(ocp)
    end
    local merlin = share .. "/merlin/vim"
    if vim.fn.isdirectory(merlin) == 1 then
      opt.rtp:append(merlin)
    end
  end,
})
