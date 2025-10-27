return {
  ---------------------------------------------------------
  -- GitHub Copilot core (inline suggestions + panel)
  ---------------------------------------------------------
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    cmd = "Copilot",
    opts = {
      suggestion = {
        enabled = false,
        auto_trigger = false,
        debounce = 75,
        keymap = {
          accept = "<M-l>",
          accept_word = false,
          accept_line = false,
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = {
        enabled = true,
        auto_refresh = false,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<M-CR>",
        },
        layout = { position = "bottom", ratio = 0.35 },
      },
      filetypes = {
        ["*"] = true,
        markdown = true,
        gitcommit = true,
        yaml = true,
      },
      server_opts_overrides = {
        offset_encoding = "utf-8" -- Set the offset encoding same as above, see `:h vim.lsp.start` for more info
      },
    },
  },
  -- Optional: integrate Copilot into nvim-cmp completion menu
  {
    "zbirenbaum/copilot-cmp",
    dependencies = { "zbirenbaum/copilot.lua" },
    opts = {},
    config = function(_, opts)
      require("copilot_cmp").setup(opts)
    end,
  },
}
