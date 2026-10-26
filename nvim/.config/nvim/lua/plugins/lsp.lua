return {
  -- Native vim.lsp. nvim-lspconfig ships per-server lsp/*.lua
  -- defaults; the config below layers overrides + keymaps on top.
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- ============================================================================
    -- Native LSP
    -- ============================================================================
    -- HOW THIS WORKS, in three layers:
    --
    --   1. nvim-lspconfig drops a file at lsp/<name>.lua on the runtimepath for
    --      every known server. That file returns a table: cmd, filetypes,
    --      root_markers. Those are the defaults; we never edit them.
    --
    --   2. vim.lsp.config("<name>", { ... }) DEEP-MERGES our table on top of the
    --      default. So we only write down what actually differs.
    --
    --   3. vim.lsp.enable({ ... }) tells Neovim to start those servers when a
    --      buffer's filetype matches. That is the whole activation story.
    --
    -- Scala is deliberately absent - nvim-metals drives its own client. See
    -- plugins/scala.lua.

    -- ============================================================================
    -- 1. WHAT DIFFERS FROM THE DEFAULTS
    -- ============================================================================

    local overrides = {
      gopls = {
        settings = {
          gopls = {
            staticcheck = true,
            gofumpt = true,
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              constantValues = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      },

      rust_analyzer = {
        settings = {
          ["rust-analyzer"] = {
            check = { command = "clippy" },
            cargo = { allFeatures = true },
            inlayHints = { closureReturnTypeHints = { enable = "always" } },
          },
        },
      },

      lua_ls = {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
            hint = { enable = true },
          },
        },
      },

      -- nixpkgs ships jdtls as a self-contained launcher script. lspconfig's
      -- default cmd is a function that builds a manual-install invocation, and on
      -- 0.11.0 it errors ("attempt to index local 'config'"), so the server never
      -- starts. Overriding cmd is what lspconfig's own docs prescribe for
      -- launcher-based installs.
      jdtls = {
        cmd = { "jdtls" },
      },

      -- lspconfig's terraformls on_attach calls vim.lsp.codelens.enable(), which
      -- is nil on nvim 0.11.0 (added in a later patch), so every attach raised
      -- ON_ATTACH_ERROR. Override it until nvim is newer.
      terraformls = {
        on_attach = function() end,
      },

      -- Homebrew's HLS is built only for the GHCs Homebrew packages (9.12.3, 9.14.1).
      -- Stack projects pin their own GHC (fds uses 9.10.3 via LTS 24), and HLS must
      -- match the project GHC exactly, so the wrapper found no binary and bailed.
      -- ghcup's HLS 2.14 bundles binaries for 9.10.3, 9.12.x and 9.14.1, but
      -- ~/.ghcup/bin is not on PATH, so point at it explicitly.
      hls = {
        cmd = { vim.fn.expand("~/.ghcup/bin/haskell-language-server-wrapper"), "--lsp" },
        -- The wrapper locates haskell-language-server-<ghc-version> via PATH, not
        -- relative to itself, so ~/.ghcup/bin has to be on PATH too. APPEND it:
        -- ~/.ghcup/bin also holds a `ghc` (9.4.8), and for loose files the wrapper
        -- picks the GHC via `ghc` on PATH. Homebrew ghc 9.14.1 must stay first.
        cmd_env = { PATH = vim.env.PATH .. ":" .. vim.fn.expand("~/.ghcup/bin") },
      },

      pyright = {
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
            },
          },
        },
      },
    }

    -- Servers we run with lspconfig's defaults untouched. Adding a language is
    -- one name here - as long as nvim-lspconfig ships lsp/<name>.lua for it.
    -- Check with :lua =vim.fn.getcompletion("", "lsp") or browse
    -- ~/.local/share/nvim/lazy/nvim-lspconfig/lsp/
    local plain = {
      -- c / c++ / objc / cuda (clangd covers all of them)
      "clangd",
      -- js / jsx / ts / tsx
      "ts_ls",
      "eslint",
      -- web
      "html",
      "cssls",
      -- data / config formats
      "jsonls",
      "yamlls",
      "taplo",            -- toml
      -- infra
      "dockerls",
      "docker_compose_language_service",
      -- shell / docs
      "bashls",
      "texlab",
      "marksman",
      -- languages
      "zls",              -- zig
      "templ",
      "ocamllsp",         -- opam install ocaml-lsp-server
    }

    -- ============================================================================
    -- 1b. A SERVER LSPCONFIG DOES NOT KNOW ABOUT
    -- ============================================================================
    -- nvim-lspconfig has no config for erlang_ls (it ships `elp`, a different
    -- Erlang server that nixpkgs does not carry). So we write the whole thing
    -- ourselves. This is the full contract - there is nothing magic in the
    -- lspconfig files beyond these three fields:
    --
    --   cmd          how to launch the server
    --   filetypes    which buffers it should attach to
    --   root_markers files that mark the project root, nearest-first
    --
    -- Any server you can launch from a shell can be wired up this way.

    vim.lsp.config("erlang_ls", {
      cmd = { "erlang_ls" },
      filetypes = { "erlang" },
      root_markers = { "rebar.config", "erlang.mk", ".git" },
    })

    -- ============================================================================
    -- 2. REGISTER + ENABLE
    -- ============================================================================

    for name, cfg in pairs(overrides) do
      vim.lsp.config(name, cfg)
    end

    local enabled = vim.tbl_keys(overrides)
    vim.list_extend(enabled, plain)
    table.insert(enabled, "erlang_ls")

    -- Enabling a server whose binary is missing is harmless: Neovim logs to
    -- :checkhealth vim.lsp and moves on. So this list can run ahead of what is
    -- actually installed.
    vim.lsp.enable(enabled)

    -- ============================================================================
    -- 2b. WORKAROUND: clangd inlay-hint noise on nvim 0.11.0
    -- ============================================================================
    -- Neovim 0.11.0's inlay-hint refresh issues textDocument/inlayHint for the
    -- CURRENT buffer, even when that buffer is a terminal with a term:// URI.
    -- clangd only accepts file:// URIs, so it rejects the request and the
    -- rejection surfaces as an error notification every time a terminal split
    -- opens - which <leader>ru does constantly in C/C++ buffers.
    --
    -- Gating our own inlay_hint.enable() on buftype does NOT help: the request is
    -- generated inside Neovim's refresh path, not by our call. nixpkgs has no
    -- newer nvim to upgrade into, so the remaining option is to drop this one
    -- message. Delete this block once nvim is past 0.11.0.
    do
      local base_notify = vim.notify
      vim.notify = function(msg, level, opts)
        if
          type(msg) == "string"
          and msg:find("textDocument/inlayHint", 1, true)
          and msg:find("only supports 'file' URI", 1, true)
        then
          return
        end
        return base_notify(msg, level, opts)
      end
    end

    -- ============================================================================
    -- 3. DIAGNOSTICS
    -- ============================================================================
    -- One global call. Diagnostics are core Neovim, not LSP-specific - nvim-lint
    -- feeds this same pipeline.

    vim.diagnostic.config({
      virtual_text = { spacing = 2, prefix = "●" },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "✗",
          [vim.diagnostic.severity.WARN]  = "⚠",
          [vim.diagnostic.severity.INFO]  = "ℹ",
          [vim.diagnostic.severity.HINT]  = "➜",
        },
      },
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      float = { border = "single", source = true },
    })

    vim.keymap.set("n", "[g", function() vim.diagnostic.jump({ count = -1, float = true }) end,
      { silent = true, desc = "Prev diagnostic" })
    vim.keymap.set("n", "]g", function() vim.diagnostic.jump({ count = 1, float = true }) end,
      { silent = true, desc = "Next diagnostic" })
    vim.keymap.set("n", "<leader>dia", vim.diagnostic.setloclist,
      { silent = true, desc = "Diagnostics to loclist" })

    -- Virtual text is truncated at the window edge, so long messages ("...for
    -- further information visit https://...") get cut off. Two ways to read the
    -- whole thing:
    --   <leader>dd  float the full diagnostic for the line under the cursor
    --   <leader>dv  toggle virtual_lines, which renders complete messages inline
    --               underneath the offending line (Neovim 0.11+)
    vim.keymap.set("n", "<leader>dd", function()
      vim.diagnostic.open_float(nil, { scope = "line", border = "single", source = true })
    end, { silent = true, desc = "Show full diagnostic" })

    vim.keymap.set("n", "<leader>dv", function()
      local cfg = vim.diagnostic.config()
      local on = cfg.virtual_lines ~= false and cfg.virtual_lines ~= nil
      vim.diagnostic.config({
        virtual_lines = not on and { current_line = true } or false,
        virtual_text = on and { spacing = 2, prefix = "●" } or false,
      })
      vim.notify("virtual_lines " .. (not on and "on" or "off"))
    end, { silent = true, desc = "Toggle inline full diagnostics" })

    -- ============================================================================
    -- 4. PER-BUFFER SETUP
    -- ============================================================================
    -- Neovim 0.11 already binds these the moment a client attaches, for free:
    --
    --     grn  rename            gra  code action        grr  references
    --     gri  implementation    grt  type definition    gO   document symbols
    --     K    hover             <C-s> signature help (insert mode)
    --     <C-]> definition (via tagfunc)
    --
    -- So this block only adds what 0.11 does NOT give us. Everything below is
    -- buffer-local, which is the key idea: a buffer-local map shadows a global
    -- one, so LSP keys only exist in buffers that actually have a server.

    vim.api.nvim_create_augroup("lsp_attach", { clear = true })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = "lsp_attach",
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
          return
        end
        local bufnr = args.buf

        local function bmap(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = "lsp: " .. desc })
        end

        -- gd: the one navigation key 0.11 leaves out (it only wires <C-]>).
        bmap("n", "gd", vim.lsp.buf.definition, "Definition")

        -- Hover. The default is K, but keymaps.lua maps K to the 25k motion
        -- globally, and that wins here because we would otherwise be fighting
        -- our own config. To reclaim the standard key, delete the K mapping in
        -- keymaps.lua and drop this line - 0.11 binds K by itself.
        bmap("n", "<leader>k", function() vim.lsp.buf.hover({ border = "single" }) end, "Hover")

        -- Format. 0.11 points 'formatexpr' at vim.lsp.formatexpr() on attach, but
        -- only for servers advertising textDocument/rangeFormatting - gopls does
        -- not, so gq falls back to the built-in formatter there. This mapping
        -- always uses the LSP.
        -- <leader>f is the fzf-lua prefix now, so format moved to <leader>cf.
        -- Leaving it on <leader>f would make every fzf keystroke wait out
        -- timeoutlen in LSP buffers.
        -- Only when the server can actually format. marksman (markdown) cannot,
        -- and binding it anyway would shadow the ftplugin's prettier/gq mapping.
        if client:supports_method("textDocument/formatting") then
          bmap({ "n", "x" }, "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "Format")
        end

        -- Inlay hints, where the server offers them.
        if client:supports_method("textDocument/inlayHint") and vim.bo[bufnr].buftype == "" then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          bmap("n", "<leader>ih", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
          end, "Toggle inlay hints")
        end

        -- Highlight other references to the symbol under the cursor.
        -- (This is what the old CursorHold -> CocActionAsync("highlight") did.)
        if client:supports_method("textDocument/documentHighlight") then
          local hl = vim.api.nvim_create_augroup("lsp_doc_highlight_" .. bufnr, { clear = true })
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            group = hl, buffer = bufnr, callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            group = hl, buffer = bufnr, callback = vim.lsp.buf.clear_references,
          })
        end
      end,
    })

    vim.api.nvim_create_autocmd("LspDetach", {
      group = "lsp_attach",
      callback = function(args)
        pcall(vim.api.nvim_del_augroup_by_name, "lsp_doc_highlight_" .. args.buf)
        vim.lsp.buf.clear_references()
      end,
    })

    -- ============================================================================
    -- 5. COMMANDS
    -- ============================================================================

    vim.api.nvim_create_user_command("Format", function()
      vim.lsp.buf.format({ async = true })
    end, { desc = "Format buffer via LSP" })

    vim.api.nvim_create_user_command("OR", function()
      vim.lsp.buf.code_action({
        context = { only = { "source.organizeImports" }, diagnostics = {} },
        apply = true,
      })
    end, { desc = "Organize imports" })
  end,
}
