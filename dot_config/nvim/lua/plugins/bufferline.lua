return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      diagnostics = "nvim_lsp",
      offsets = {
        { filetype = "neo-tree", text = "File Explorer", highlight = "Directory" },
      },
    },
  },
}
