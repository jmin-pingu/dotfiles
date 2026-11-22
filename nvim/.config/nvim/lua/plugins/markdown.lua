return {
  -- Pretty headings, code fences and lists in markdown buffers (chapter notes).
  -- Toggle with :RenderMarkdown toggle.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      -- No heading styling: headings keep only normal syntax colours.
      -- Code blocks and the rest still render.
      heading = { enabled = false },
      -- Leave LaTeX as raw source. Math is read in a PDF via <leader>mp.
      latex = { enabled = false },
    },
  },
}
