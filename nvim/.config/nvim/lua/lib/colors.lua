-- ============================================================================
-- Colors: cterm index -> hex bridge
-- ============================================================================
-- With termguicolors OFF, Neovim honours ctermfg/ctermbg and ignores guifg/
-- guibg. Turning it ON inverts that: the gui* halves become live and every
-- cterm* value goes inert. Since the theme rules in autocmds.lua were written
-- as cterm indices, they would all silently stop applying.
--
-- Rather than hand-convert 47 rules, this module resolves a cterm index to
-- the hex the terminal would have drawn, and hi() emits BOTH halves. The
-- theme tables keep their readable 0-255 numbers and render the same either
-- way - so flipping termguicolors back is a one-line change, not a rewrite.

local M = {}

-- Indices 0-15 are whatever the terminal's palette says, so they are taken
-- from the active Ghostty theme (vesper). Change these if you change themes:
--   /Applications/Ghostty.app/Contents/Resources/ghostty/themes/<name>
local base16 = {
  [0]  = "#101010", [1]  = "#f5a191", [2]  = "#90b99f", [3]  = "#e6b99d",
  [4]  = "#aca1cf", [5]  = "#e29eca", [6]  = "#ea83a5", [7]  = "#a0a0a0",
  [8]  = "#7e7e7e", [9]  = "#ff8080", [10] = "#99ffe4", [11] = "#ffc799",
  [12] = "#b9aeda", [13] = "#ecaad6", [14] = "#f591b2", [15] = "#ffffff",
}

-- 16-255 are fixed by the xterm-256 standard, so these convert exactly and
-- the rendered colour is identical to what cterm produced.
local cube = { 0, 95, 135, 175, 215, 255 }

---@param n integer cterm colour index, 0-255
---@return string hex e.g. "#5f8700"
function M.hex(n)
  if base16[n] then
    return base16[n]
  end
  if n >= 16 and n <= 231 then
    local i = n - 16
    local r = cube[math.floor(i / 36) + 1]
    local g = cube[math.floor((i % 36) / 6) + 1]
    local b = cube[(i % 6) + 1]
    return ("#%02x%02x%02x"):format(r, g, b)
  end
  if n >= 232 and n <= 255 then
    local v = 8 + (n - 232) * 10
    return ("#%02x%02x%02x"):format(v, v, v)
  end
  return "NONE"
end

-- ============================================================================
-- Built-in terminal palette
-- ============================================================================
-- Neovim's :terminal renders ANSI colours from g:terminal_color_0..15.
--
-- While termguicolors was off, the real terminal drew those colours and they
-- matched vesper for free. With it on, Neovim renders them itself and falls
-- back to its own hardcoded defaults when these variables are unset - which is
-- why `cargo run` output through <leader>ru came out with the wrong colours.
--
-- Point them at the same palette everything else uses. Re-applied on
-- ColorScheme because loading a scheme can clear them.
local function apply_terminal_palette()
  for i = 0, 15 do
    vim.g["terminal_color_" .. i] = base16[i]
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("terminal_palette", { clear = true }),
  pattern = "*",
  callback = apply_terminal_palette,
})

apply_terminal_palette()

--- Set a highlight group in both colour modes.
---
--- Uses :highlight rather than nvim_set_hl on purpose: :highlight MERGES into
--- the group, keeping whatever the colorscheme already set for attributes we
--- do not mention, while nvim_set_hl REPLACES the whole group. The theme rules
--- below rely on merge semantics - e.g. `CursorLine = { bg = 236 }` must leave
--- the scheme's foreground alone.
---
---@param group string highlight group name
---@param spec table { fg = <0-255|"none">, bg = ..., attr = "underline" }
function M.hi(group, spec)
  local parts = {}

  local function add(key, value)
    if value == nil then
      return
    end
    if value == "none" or value == "NONE" then
      parts[#parts + 1] = ("cterm%s=NONE gui%s=NONE"):format(key, key)
    else
      parts[#parts + 1] = ("cterm%s=%d gui%s=%s"):format(key, value, key, M.hex(value))
    end
  end

  add("fg", spec.fg)
  add("bg", spec.bg)

  if spec.attr then
    parts[#parts + 1] = ("cterm=%s gui=%s"):format(spec.attr, spec.attr)
  end

  if #parts > 0 then
    vim.cmd(("highlight %s %s"):format(group, table.concat(parts, " ")))
  end
end

return M
