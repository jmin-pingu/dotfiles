return {
  -- Pretty headings, code fences and lists in markdown buffers (chapter notes).
  -- Toggle with :RenderMarkdown toggle.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      -- Quiet headings: no full-width background bars and no sign-column icon.
      -- Heading text keeps its colour.
      heading = { backgrounds = {}, sign = false },
    },
  },
}
