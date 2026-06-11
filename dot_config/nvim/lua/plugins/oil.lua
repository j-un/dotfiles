return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  -- Needed so `default_file_explorer` can hijack `nvim <dir>` at startup.
  -- Removing this breaks the `nvim .` directory hijack.
  lazy = false,
  keys = {
    { "<leader>e", function()
        if require("oil").get_current_dir() then
          require("oil").close()
        else
          require("oil").open()
        end
      end, desc = "Toggle file explorer (oil)" },
  },
  config = function(_, opts)
    require("oil").setup(opts)
    -- When a file is deleted via oil, close its buffer if open.
    vim.api.nvim_create_autocmd("User", {
      pattern = "OilActionsPost",
      callback = function(event)
        for _, action in ipairs(event.data.actions) do
          if action.type == "delete" and action.entry_type == "file" then
            local path = action.url:gsub("^oil://", "")
            local bufnr = vim.fn.bufnr(path)
            if bufnr ~= -1 then
              vim.api.nvim_buf_delete(bufnr, { force = true })
            end
          end
        end
      end,
    })
  end,
  opts = {
    default_file_explorer = true,
    delete_to_trash = false, -- Avoid depending on the `trash` CLI on macOS.
    skip_confirm_for_simple_edits = true,
    view_options = {
      show_hidden = true,
      is_hidden_file = function(name, _)
        return name == ".DS_Store" or name == ".git"
      end,
    },
    keymaps = {
      ["<CR>"]  = "actions.select",
      ["-"]     = "actions.parent",
      ["<C-s>"] = { "actions.select", opts = { vertical = true } },
      ["<C-x>"] = { "actions.select", opts = { horizontal = true } }, -- Was <C-h>; avoid window-left collision.
      ["<C-p>"] = "actions.preview",
      ["<C-c>"] = "actions.close",
      ["g."]    = "actions.toggle_hidden",
      ["gx"]    = "actions.open_external",
    },
  },
}
