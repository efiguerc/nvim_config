return {
  ---------------------------------------------------------
  -- Treesitter for better Ruby/ERB/JS/TS syntax and folding
  ---------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "ruby",
	      "embedded_template",
        "bash",
        "json",
        "yaml",
        "html",
        "css",
        "javascript",
        "python",
        "typescript",
        "tsx",
        "markdown",
        "markdown_inline",
        "query",
        "diff",
      },
      highlight = { enable = true },
      indent = { enable = true, disable = { "ruby" } }, -- ruby indentation via LSP/other tools tends to be better
      incremental_selection = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
      vim.treesitter.language.register('embedded_template', 'eruby')
    end,
  },
}
