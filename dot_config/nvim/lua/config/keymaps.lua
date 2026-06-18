vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- Format
map("n", "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format file" })

-- Buffers
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>",         { desc = "Close buffer" })

-- Git
map("n", "<leader>gb", function()
  require("gitsigns").blame_line({ full = true })
end, { desc = "Git blame line" })

-- VSCode-style comment toggle.
-- Built-in gcc/gc (Neovim 0.10+) requires remap=true to expand the <Plug> mapping.
-- Terminals send <C-_> for Ctrl+/ by default; <C-/> covers kitty/ghostty keyboard
-- protocol; <D-/> covers macOS GUI clients (neovide etc.).
for _, key in ipairs({ "<C-_>", "<C-/>", "<D-/>" }) do
  vim.keymap.set("n", key, "gcc",          { remap = true, desc = "Toggle comment line" })
  vim.keymap.set("x", key, "gc",           { remap = true, desc = "Toggle comment selection" })
  vim.keymap.set("i", key, "<Esc>gccgi",   { remap = true, desc = "Toggle comment (insert)" })
end
