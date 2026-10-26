-- ============================================================================
-- Color Scheme
-- ============================================================================

vim.cmd.colorscheme("minimalist")

-- Favorites, if you want to switch:
--   happy_hacking  rdark-terminal2  twilight256  nord  habamax  mies  default

-- Let the terminal background show through.
local transparent = {
  "Normal",
  "NonText",
  "SignColumn",
  "EndOfBuffer",
  "LineNr",
}

local function clear_backgrounds()
  for _, group in ipairs(transparent) do
    -- Read the group first and re-set it with only the background dropped,
    -- so foregrounds and attributes the scheme chose are preserved.
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.bg = nil
    hl.ctermbg = nil
    vim.api.nvim_set_hl(0, group, hl)
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("transparent_background", { clear = true }),
  pattern = "*",
  callback = clear_backgrounds,
})

clear_backgrounds()
