return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      "go", "typescript", "tsx", "javascript",
      "hcl", "terraform",
      "python",
      "markdown", "markdown_inline",
      "yaml", "toml", "json", "html",
      "lua", "vim", "vimdoc", "bash",
    },
    highlight = { enable = true },
    indent = { enable = true },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
