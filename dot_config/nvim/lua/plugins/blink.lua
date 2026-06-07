return {
  "saghen/blink.cmp",
  version = "1.*",
  opts = {
    keymap = { preset = "default" },
    signature = { enabled = true },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
  },
}
