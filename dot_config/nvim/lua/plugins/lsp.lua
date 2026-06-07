return {
  "neovim/nvim-lspconfig",
  dependencies = { "saghen/blink.cmp" },
  config = function()
    vim.diagnostic.config({
      virtual_text = true,
      severity_sort = true,
      float = { border = "rounded" },
    })

    -- Buffer-local LSP keymaps
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(ev)
        local map = vim.keymap.set
        local buf = ev.buf
        local opts = function(desc) return { buffer = buf, desc = desc } end

        map("n", "gd",         vim.lsp.buf.definition,     opts("Go to definition"))
        map("n", "gr",         vim.lsp.buf.references,     opts("References"))
        map("n", "gi",         vim.lsp.buf.implementation, opts("Go to implementation"))
        map("n", "K",          vim.lsp.buf.hover,          opts("Hover docs"))
        map("n", "<leader>rn", vim.lsp.buf.rename,         opts("Rename"))
        map("n", "<leader>ca", vim.lsp.buf.code_action,    opts("Code action"))
        map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts("Prev diagnostic"))
        map("n", "]d", function() vim.diagnostic.jump({ count =  1, float = true }) end, opts("Next diagnostic"))
      end,
    })

    -- Apply blink.cmp capabilities to all servers
    vim.lsp.config("*", {
      capabilities = require("blink.cmp").get_lsp_capabilities(),
    })

    vim.lsp.enable({
      "gopls",
      "ts_ls",
      "terraformls",
      "pyright",
      "marksman",
      "yamlls",
      "taplo",
      "jsonls",
      "html",
    })
  end,
}
