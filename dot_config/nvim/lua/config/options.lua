-- Prepend mise shims to PATH so LSP servers and formatters are found without a shell
local mise_data = vim.env.MISE_DATA_DIR or (vim.env.HOME .. "/.local/share/mise")
vim.env.PATH = mise_data .. "/shims:" .. vim.env.PATH

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.smartindent = true
opt.cursorline = true
opt.clipboard = "unnamedplus"
opt.signcolumn = "yes"
opt.termguicolors = true
opt.mouse = "a"
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 8
opt.updatetime = 250
opt.autoread = true

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  command = "checktime",
})

-- Disable unused providers to suppress checkhealth warnings
vim.g.loaded_node_provider  = 0
vim.g.loaded_perl_provider  = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider  = 0
