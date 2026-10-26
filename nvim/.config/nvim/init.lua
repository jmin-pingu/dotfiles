-- ============================================================================
-- Neovim Configuration
-- ============================================================================

-- Disable netrw FIRST (before any plugins load)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Set leader keys FIRST (before lazy.nvim)
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins: one file per plugin (or per group) in lua/plugins/, each returning
-- its lazy.nvim spec with the config inline. Adding a plugin is adding a file.
require("lazy").setup({ { import = "plugins" } }, {
  -- lazy.nvim bootstraps a private luarocks for plugins that need it. Nothing
  -- here does, and it costs an error and two warnings in :checkhealth.
  rocks = { enabled = false },
})

-- Core: pure vim, no plugin knowledge.
require("core.options")
require("core.keymaps")
require("core.autocmds")
require("core.colorscheme")
-- Lib: your own features.
require("lib.runners")
require("lib.hs_source")
require("lib.colab")
