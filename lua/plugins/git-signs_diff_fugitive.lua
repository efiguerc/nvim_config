return {
  ---------------------------------------------------------
  -- Git UX: gitsigns + diffview + fugitive
  ---------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
        end
        map("n", "]h", gs.next_hunk, "Git: Next hunk")
        map("n", "[h", gs.prev_hunk, "Git: Prev hunk")
        map("n", "<leader>hs", gs.stage_hunk, "Git: Stage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "Git: Reset hunk")
        map("n", "<leader>hp", gs.preview_hunk, "Git: Preview hunk")
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Git: Blame line")
      end,
    },
  },
  { "tpope/vim-fugitive", cmd = { "Git", "G", "Gdiffsplit" } },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
}
