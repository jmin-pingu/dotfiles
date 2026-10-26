-- ============================================================================
-- :HsSource - read GHC library source without leaving Neovim
-- ============================================================================
-- Homebrew's GHC ships no library sources or .hie files, so `gd` on anything
-- from base comes back empty and hover only names the defining module. This
-- takes that module name and fetches the file from GHC's repository for the
-- installed GHC version, then opens it read-only in a split.
--
--   :HsSource                 module of the symbol under the cursor (via HLS hover)
--   :HsSource Data.Maybe      a module by name
--
-- Only the GHC boot libraries live in the GHC repo. Anything else (containers,
-- text, ...) is a separate package, so for those the Hackage source page is
-- opened in the browser instead.

local M = {}

-- package name -> path of its source root inside the GHC repository
local ghc_repo_paths = {
  ["ghc-internal"]     = "libraries/ghc-internal/src/",
  ["base"]             = "libraries/base/src/",
  ["ghc-prim"]         = "libraries/ghc-prim/",
  ["ghc-bignum"]       = "libraries/ghc-bignum/src/",
  ["ghc-experimental"] = "libraries/ghc-experimental/src/",
  ["template-haskell"] = "libraries/template-haskell/",
}

--- "9.14.1" -> "ghc-9.14", the release branch in the GHC repo.
local function ghc_branch()
  local v = vim.fn.systemlist({ "ghc", "--numeric-version" })[1] or ""
  local major, minor = v:match("^(%d+)%.(%d+)")
  if not major then
    return nil, ("could not read GHC version (%q)"):format(v)
  end
  return ("ghc-%s.%s"):format(major, minor)
end

--- Ask HLS what is under the cursor. Returns module, package (package may be nil).
local function module_under_cursor()
  local client = vim.lsp.get_clients({ bufnr = 0, name = "hls" })[1]
  if not client then
    return nil, "hls is not attached to this buffer"
  end
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  local res = client:request_sync("textDocument/hover", params, 5000, 0)
  local contents = res and res.result and res.result.contents
  local text = type(contents) == "table" and contents.value or contents
  if type(text) ~= "string" then
    return nil, "no hover information here"
  end
  -- hover renders: *Defined in ‘GHC.Internal.Control.Monad.Fail’* *(ghc-internal-9.1401.0)*
  local module = text:match("Defined in ‘([%w%.]+)’")
  if not module then
    return nil, "hover text has no 'Defined in' (is the symbol from a library?)"
  end
  local package = text:match("%(([%w%-]-)%-[%d%.]+%)")
  return module, package
end

--- Open `lines` as a read-only haskell buffer in a split and look for `word`.
local function show(lines, name, word)
  vim.cmd("botright vsplit")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_name(buf, "hs-source://" .. name)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "haskell"
  vim.bo[buf].modifiable = false
  vim.api.nvim_win_set_buf(0, buf)
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true, desc = "Close source" })
  if word and word ~= "" then
    -- Prefer the declaration over the first mention.
    local pat = [[\v^(class|data|newtype|type|instance)>.*<]] .. word .. [[>]]
    if vim.fn.search(pat, "cw") == 0 then
      vim.fn.search([[\<]] .. word .. [[\>]], "cw")
    end
    vim.cmd("normal! zz")
  end
end

--- Fetch the module's source for this GHC and show it. Cached under
--- stdpath("cache")/hs-source so a module is downloaded once per GHC version.
local function open_module(module, package, word)
  local repo_path = package and ghc_repo_paths[package]
  if not repo_path then
    -- Not a boot library: send it to Hackage's hyperlinked source instead.
    local url = ("https://hackage.haskell.org/package/%s/docs/src/%s.html"):format(package or "base", module)
    vim.notify(("%s is not in the GHC repo; opening Hackage"):format(package or module))
    vim.ui.open(url)
    return
  end

  local branch, err = ghc_branch()
  if not branch then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local rel = module:gsub("%.", "/") .. ".hs"
  local cache = vim.fn.stdpath("cache") .. "/hs-source/" .. branch .. "/" .. rel
  if vim.uv.fs_stat(cache) then
    show(vim.fn.readfile(cache), module, word)
    return
  end

  local url = ("https://raw.githubusercontent.com/ghc/ghc/%s/%s%s"):format(branch, repo_path, rel)
  vim.notify("fetching " .. module .. " ...")
  vim.system({ "curl", "-sfL", url }, { text = true }, function(out)
    vim.schedule(function()
      if out.code ~= 0 or out.stdout == "" then
        vim.notify(("could not fetch %s (curl exit %d)\n%s"):format(module, out.code, url), vim.log.levels.ERROR)
        return
      end
      vim.fn.mkdir(vim.fn.fnamemodify(cache, ":h"), "p")
      vim.fn.writefile(vim.split(out.stdout, "\n", { plain = true }), cache)
      show(vim.fn.readfile(cache), module, word)
    end)
  end)
end

function M.source(arg)
  if arg and arg ~= "" then
    -- Explicit module: assume ghc-internal unless it is plainly base-shaped.
    local package = arg:match("^GHC%.Internal") and "ghc-internal" or "base"
    open_module(arg, package, nil)
    return
  end
  local word = vim.fn.expand("<cword>")
  local module, package_or_err = module_under_cursor()
  if not module then
    vim.notify(package_or_err, vim.log.levels.WARN)
    return
  end
  open_module(module, package_or_err, word)
end

vim.api.nvim_create_user_command("HsSource", function(opts)
  M.source(opts.args)
end, { nargs = "?", desc = "Open GHC library source for the module under the cursor (or given)" })

return M
