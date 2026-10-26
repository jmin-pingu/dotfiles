-- ============================================================================
-- Per-filetype run/test commands
-- ============================================================================
-- Buffer-local <leader>ru (run) and <leader>rt (test), set by a FileType
-- autocmd so each language gets its own command and nothing leaks into
-- unrelated buffers.
--
-- A command is either:
--   "string"                  run from the FILE's own directory
--   { cmd = "...", root = X } run from the nearest ancestor containing X
--                             (X is a filename, a list of filenames, or a
--                             fun(name, path) predicate)
--   function() ... end        run as Lua, no terminal - or RETURN either form
--                             above to choose the command at runtime
--
-- Inside a command string, "%" expands to the shell-escaped absolute path of
-- the current file.
--
-- Adding a language is one line. Nothing here has to exist on your PATH -
-- a missing binary reports itself rather than opening an empty terminal.

--- A cabal package root: an explicit cabal.project, or any *.cabal file.
--- vim.fs.root takes a predicate, which plain filename markers cannot express.
--- Two traps a naive "%.cabal$" falls into: cabal's own ~/.cabal CONFIG DIR
--- has a basename ending in ".cabal", and so would any directory named that -
--- so require a real basename before the suffix, and require a file.
---@param name string basename
---@param dir string directory containing it
---@return boolean
local function is_cabal_project(name, dir)
  if name ~= "cabal.project" and not name:match("^[^.].*%.cabal$") then
    return false
  end
  local st = vim.uv.fs_stat(dir .. "/" .. name)
  return st ~= nil and st.type == "file"
end

local runners = {
  -- ---- compiled, single file -------------------------------------------
  c    = { run = "cc % -o /tmp/nvim-run.out && /tmp/nvim-run.out" },
  cpp  = { run = "c++ -std=c++20 % -o /tmp/nvim-run.out && /tmp/nvim-run.out" },
  zig  = {
    -- `zig run` needs the file that defines `pub fn main`. Pressing <leader>ru
    -- in memory.zig (just a struct) died with "struct 'memory' has no member
    -- named 'main'" deep inside std/start.zig - a confusing error for a runner
    -- that was doing exactly what it was told. So: run this file if it has a
    -- main, else the project via build.zig, else whichever file nearby does.
    run = function()
      local here = vim.fn.expand("%:p")
      if vim.fn.search("\\<pub\\s\\+fn\\s\\+main\\>", "nw") ~= 0 then
        return "zig run %"
      end
      -- `zig build` walks up from cwd to find build.zig itself, so no cd needed.
      if vim.fs.root(0, "build.zig") then
        vim.notify("no `main` in this file - running the project (zig build run)")
        return "zig build run"
      end
      -- No project: look for a sibling (or nested) file that defines main.
      local dir = vim.fn.expand("%:p:h")
      local hits = vim.fn.systemlist({ "grep", "-rl", "--include=*.zig", "-E", "pub\\s+fn\\s+main\\b", dir })
      hits = vim.tbl_filter(function(f) return f ~= here end, hits)
      if #hits == 1 then
        vim.notify("no `main` in this file - running " .. hits[1]:sub(#dir + 2))
        return "zig run " .. vim.fn.shellescape(hits[1])
      elseif #hits > 1 then
        table.sort(hits)
        vim.notify(("%d files define main; running %s"):format(#hits, hits[1]:sub(#dir + 2)))
        return "zig run " .. vim.fn.shellescape(hits[1])
      end
      vim.notify("no `main` anywhere under " .. dir .. " - typechecking instead")
      return "zig build-obj -fno-emit-bin %"
    end,
    test = "zig test %",
  },

  -- ---- project-based ----------------------------------------------------
  rust = {
    run  = { cmd = "cargo run",  root = "Cargo.toml" },
    test = { cmd = "cargo test", root = "Cargo.toml" },
  },
  go = {
    -- `go run .` from the file's directory, so multi-file packages work;
    -- tests run from the module root so ./... covers everything.
    run  = "go run .",
    test = { cmd = "go test ./...", root = { "go.work", "go.mod" } },
  },
  haskell = {
    -- `ghci file.hs` only searches "." and the file's own directory, so any
    -- import of a sibling module dies with "Could not find module" the moment
    -- the file lives in a package (src/Set/RBTree.hs importing Set). Hand the
    -- project to the build tool instead - it knows the source dirs AND the
    -- dependencies - and keep bare ghci for a loose scratch file.
    repl = function()
      if vim.fs.root(0, "stack.yaml") then
        return { cmd = "stack ghci", root = "stack.yaml" }
      end
      if vim.fs.root(0, is_cabal_project) then
        return { cmd = "cabal repl", root = is_cabal_project }
      end
      return "ghci %"
    end,
    -- runghc needs a `main`. A scratch file that is just definitions has none
    -- and dies with "Not in scope: 'main'", which looks like a broken runner
    -- but is not. Typecheck those instead of pretending to run them.
    run = function()
      if vim.fn.search("^main\\>", "nw") ~= 0 then
        return "runghc %"
      end
      vim.notify("no `main` in this file - typechecking instead")
      return "ghc -fno-code %"
    end,
    test = { cmd = "stack test", root = { "stack.yaml", "package.yaml" } },
    -- Binary lands next to the source (recursion.hs -> recursion), like a
    -- hand-run `ghc`. The .hi/.o clutter goes to /tmp instead.
    build = function()
      return "ghc -outputdir /tmp/nvim-hs-build % -o " .. vim.fn.shellescape(vim.fn.expand("%:p:r"))
    end,
  },
  scala = {
    repl = "scala-cli repl %",
    run  = "scala-cli run %",
    test = { cmd = "sbt test", root = "build.sbt" },
  },
  java = {
    -- JDK 11+ single-file source mode; no separate javac step.
    run = "java %",
  },
  terraform = {
    run = { cmd = "terraform plan", root = { ".terraform", "main.tf" } },
  },
  templ = { run = "templ generate" },
  -- No local GPU: compile and run on a Colab VM (see lib/colab.lua).
  cuda = {
    run = function()
      require("lib.colab").run_cu()
    end,
  },

  -- ---- interpreted ------------------------------------------------------
  python = {
    -- -i runs the file then drops into the REPL with everything still bound.
    repl = "python3 -i %",
    run  = "python3 %",
    test = { cmd = "pytest", root = { "pyproject.toml", "setup.py", ".git" } },
  },
  javascript = { run = "node %", repl = "node -i" },
  typescript = {
    -- Node 22 strips types natively, so this needs no tsx/ts-node download.
    run = "node --experimental-strip-types %",
  },
  ocaml   = { run = "ocaml %", repl = "ocaml -init %" },
  erlang  = { run = "escript %", repl = "erl" },
  sh      = { run = "bash %" },
  bash    = { run = "bash %" },
  tex     = { run = "latexmk -pdf %" },
  plaintex = { run = "latexmk -pdf %" },

  -- ---- other ------------------------------------------------------------
  dockerfile = { run = "docker build -f % ." },
  lua = {
    -- Sourcing is what you actually want inside a Neovim config.
    run = function()
      vim.cmd("source %")
      vim.notify("sourced " .. vim.fn.expand("%:t"))
    end,
  },
}

-- ============================================================================
-- Build systems
-- ============================================================================
-- The table above answers "run THIS FILE". A project with a build system
-- wants a different question answered: "build/run/test THIS PROJECT". That is
-- orthogonal to filetype - a Makefile drives C, Go or LaTeX all the same - so
-- it gets its own table and its own keys:
--
--   <leader>rp   run the project      <leader>rb   build the project
--   <leader>rc   the project's tests
--
-- When no build system is found, each key falls back to the same-named
-- per-filetype command above (run / build / test), so <leader>rb on a loose
-- haskell file still compiles it.
--
-- Detection walks up from the current file and picks the DEEPEST matching
-- marker, so a nested subproject wins over the repository root. A marker
-- sitting in $HOME itself is ignored: a flake.nix there is a system config,
-- not the project of every file under it.

local build_systems = {
  { name = "just",   markers = { "justfile", "Justfile", ".justfile" },
    build = "just build", run = "just run", test = "just test" },

  { name = "cmake",  markers = { "CMakeLists.txt" },
    -- Assumes an out-of-source build in ./build (cmake -B build).
    build = "cmake --build build",
    run   = "cmake --build build && ctest --test-dir build -N",
    test  = "ctest --test-dir build --output-on-failure" },

  { name = "bazel",  markers = { "MODULE.bazel", "WORKSPACE", "WORKSPACE.bazel" },
    build = "bazel build //...", run = "bazel run //...", test = "bazel test //..." },

  { name = "nix",    markers = { "flake.nix" },
    build = "nix build", run = "nix run", test = "nix flake check" },

  { name = "make",   markers = { "Makefile", "makefile", "GNUmakefile" },
    build = "make", run = "make run", test = "make test" },

  { name = "cargo",  markers = { "Cargo.toml" },
    build = "cargo build", run = "cargo run", test = "cargo test" },

  { name = "go",     markers = { "go.work", "go.mod" },
    build = "go build ./...", run = "go run .", test = "go test ./..." },

  -- `zig build test` runs the `test` step build.zig declares (the zig init
  -- template wires it to every module). Per-file `zig test %` stays on <leader>rt.
  { name = "zig",    markers = { "build.zig" },
    build = "zig build", run = "zig build run", test = "zig build test" },
}

--- Find the nearest build system, preferring the deepest root.
---@return table|nil spec, string|nil root
local function detect_build_system()
  local best, best_root
  for _, bs in ipairs(build_systems) do
    local root = vim.fs.root(0, bs.markers)
    if root == vim.uv.os_homedir() then
      root = nil
    end
    -- Deeper root == more specific project. String length is a valid proxy
    -- because every candidate is an ancestor of the same file.
    if root and (not best_root or #root > #best_root) then
      best, best_root = bs, root
    end
  end
  return best, best_root
end

local function expand(cmd)
  return (cmd:gsub("%%", vim.fn.shellescape(vim.fn.expand("%:p"))))
end

--- Open a bottom split running `cmd` in `dir`. Shared by the filetype
--- runners and the build-system keys.
---@param shell_cmd string already %-expanded
---@param dir string working directory
local function run_in_terminal(shell_cmd, dir)
  -- `botright 15split` opens the new window on the SAME buffer, and
  -- jobstart(term=true) converts the CURRENT buffer rather than making a new
  -- one - so a plain split turns the file you are editing into a terminal.
  -- `new` splits with a fresh empty buffer instead.
  vim.cmd("botright 15new")
  vim.bo.bufhidden = "wipe"
  vim.fn.jobstart(shell_cmd, { term = true, cwd = dir })
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = 0, silent = true, desc = "Close output" })
end

--- Run one command of a filetype's spec in a terminal split.
---@param spec table the runners[ft] entry
---@param key string "run" or "test"
local function execute(spec, key)
  local entry = spec[key]
  if not entry then
    vim.notify(("no %s command for filetype %q"):format(key, vim.bo.filetype), vim.log.levels.WARN)
    return
  end

  vim.cmd("silent! write")

  local cmd, root

  if type(entry) == "function" then
    -- A function either does the whole job itself and returns nil (the lua
    -- "source this file" action), or produces a command. What it produces is
    -- then treated exactly like a literal entry, so a runtime choice can pick
    -- a working directory too - not just a command string.
    entry = entry()
    if entry == nil then
      return
    end
  end

  if type(entry) == "table" then
    cmd, root = entry.cmd, entry.root
  else
    cmd = entry
  end

  -- Report a missing toolchain instead of flashing an empty terminal.
  -- Take everything up to the first space. A character class misses binaries
  -- with punctuation - "c++" matched only "c", so the cpp runner reported
  -- `"c" is not installed`. %S+ handles c++, scala-cli, npx and friends.
  local binary = cmd:match("^%s*(%S+)")
  if binary and vim.fn.executable(binary) == 0 then
    vim.notify(("%s: %q is not installed"):format(key, binary), vim.log.levels.ERROR)
    return
  end

  -- Expand "%" and resolve the root while the SOURCE buffer is still current.
  -- Doing it after the split would expand against the new empty buffer and
  -- silently drop the filename from the command.
  local shell_cmd = expand(cmd)
  local dir = root and vim.fs.root(0, root) or vim.fn.expand("%:p:h")
  if not dir then
    vim.notify(("could not find project root (%s)"):format(vim.inspect(root)), vim.log.levels.ERROR)
    return
  end

  run_in_terminal(shell_cmd, dir)
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("filetype_runners", { clear = true }),
  pattern = vim.tbl_keys(runners),
  callback = function(args)
    local spec = runners[vim.bo[args.buf].filetype]
    if not spec then
      return
    end

    local function map(lhs, key, desc)
      vim.keymap.set("n", lhs, function()
        execute(spec, key)
      end, { buffer = args.buf, silent = true, desc = desc })
    end

    map("<leader>ru", "run", "Run file/project")
    map("<leader>rt", "test", "Run tests")
    map("<leader>ri", "repl", "Open REPL with this file")
  end,
})

-- ============================================================================
-- PROJECT-LEVEL KEYS
-- ============================================================================
-- Global, not buffer-local: any file in a project should be able to build it.

local function run_build_system(key)
  local bs, root = detect_build_system()
  if not bs then
    local spec = runners[vim.bo.filetype]
    if spec and spec[key] then
      execute(spec, key)
    else
      vim.notify(("no build system found, and no %s command for filetype %q"):format(key, vim.bo.filetype),
        vim.log.levels.WARN)
    end
    return
  end
  if not bs[key] then
    vim.notify(("%s has no %s command"):format(bs.name, key), vim.log.levels.WARN)
    return
  end
  vim.notify(("%s: %s  (%s)"):format(bs.name, bs[key], vim.fn.fnamemodify(root, ":~")))
  run_in_terminal(bs[key], root)
end

vim.keymap.set("n", "<leader>rp", function() run_build_system("run") end,
  { silent = true, desc = "Run project (build system, else file)" })
vim.keymap.set("n", "<leader>rb", function() run_build_system("build") end,
  { silent = true, desc = "Build project (build system, else file)" })
vim.keymap.set("n", "<leader>rc", function() run_build_system("test") end,
  { silent = true, desc = "Test project (build system, else file)" })

vim.api.nvim_create_user_command("BuildSystem", function()
  local bs, root = detect_build_system()
  if bs then
    vim.notify(("%s at %s"):format(bs.name, vim.fn.fnamemodify(root, ":~")))
  else
    vim.notify("no build system detected", vim.log.levels.WARN)
  end
end, { desc = "Report the detected build system" })
