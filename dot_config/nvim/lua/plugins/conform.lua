return {
  "stevearc/conform.nvim",
  event = { "BufWritePre", "BufNewFile" },
  opts = {
    formatters_by_ft = {
      go         = { "goimports" },
      typescript = { "prettier" },
      javascript = { "prettier" },
      tsx        = { "prettier" },
      jsx        = { "prettier" },
      terraform  = { "terraform_fmt" },
      python     = { "ruff_format" },
      markdown   = { "prettier" },
      yaml       = { "prettier" },
      toml       = { "taplo" },
      json       = { "prettier" },
      html       = { "prettier" },
    },
    format_on_save = {
      lsp_format = "fallback",
      timeout_ms = 2000,
    },
  },
}
