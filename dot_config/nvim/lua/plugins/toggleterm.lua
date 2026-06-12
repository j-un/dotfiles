return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { [[<C-\>]], mode = { "n", "t" }, desc = "Toggle terminal" },
    { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal: float" },
    { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal: horizontal" },
    {
      "<leader>tv",
      function()
        local count = vim.v.count == 0 and 1 or vim.v.count
        vim.cmd(count .. "ToggleTerm direction=vertical size=80")
      end,
      mode = { "n", "t" },
      desc = "Terminal: vertical [count]",
    },
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "term://*toggleterm#*",
      callback = function()
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = true })
      end,
    })
  end,
  opts = {
    open_mapping = [[<c-\>]],
    direction = "float",
    float_opts = { border = "curved" },
    shade_terminals = true,
    start_in_insert = true,
    persist_mode = true,
  },
}
