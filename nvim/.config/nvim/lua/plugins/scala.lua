return {
  -- Metals is not a plain vim.lsp.enable server; it drives its own client.
  "scalameta/nvim-metals",
  -- plenary was a top-level (eager) spec before the restructure. lazy = false
  -- keeps it eager so its startup behaviour is unchanged; drop that to make it
  -- load only with metals - nothing else here uses it.
  dependencies = { { "nvim-lua/plenary.nvim", lazy = false } },
  ft = { "scala", "sbt", "java" },
  config = function()
    -- ============================================================================
    -- Scala (nvim-metals)
    -- ============================================================================
    -- Metals is the one server that does NOT go through vim.lsp.enable. It needs
    -- a driver plugin because it manages its own build-server handshake (Bloop /
    -- sbt), import prompts, and worksheet decorations. The plugin still produces
    -- an ordinary LSP client underneath, so everything in plugins/lsp.lua's
    -- LspAttach block - gd, hover, inlay hints, document highlight - applies to
    -- Scala buffers too.

    local status_ok, metals = pcall(require, "metals")
    if not status_ok then
      return
    end

    local config = metals.bare_config()

    config.settings = {
      showImplicitArguments = true,
      showInferredType = true,
      superMethodLensesEnabled = true,
      excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
      -- Use the Nix-installed metals on PATH (macs). Hosts without it (linux)
      -- fall back to nvim-metals' own cache, filled by :MetalsInstall.
      useGlobalExecutable = vim.fn.executable("metals") == 1,
    }

    config.init_options.statusBarProvider = "off"

    -- Pick up blink's completion capabilities if blink is already loaded; metals
    -- works fine without them, so this stays optional rather than forcing a load.
    local blink_ok, blink = pcall(require, "blink.cmp")
    if blink_ok and blink.get_lsp_capabilities then
      config.capabilities = blink.get_lsp_capabilities()
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("metals_attach", { clear = true }),
      -- Java is handled by jdtls in plugins/lsp.lua, not metals.
      pattern = { "scala", "sbt" },
      callback = function()
        metals.initialize_or_attach(config)
      end,
    })
  end,
}
