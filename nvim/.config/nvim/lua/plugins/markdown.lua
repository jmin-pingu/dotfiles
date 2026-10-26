return {
  -- Pretty headings, code fences and lists in markdown buffers (chapter notes).
  -- Toggle with :RenderMarkdown toggle.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },
}
