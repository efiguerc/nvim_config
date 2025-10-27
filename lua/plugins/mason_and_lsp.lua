return {
  ---------------------------------------------------------
  -- LSP, Mason setup (Ruby, Lua, Python, etc.)
  ---------------------------------------------------------
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    opts = {
      ui = { border = "rounded" },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      -- ensure_installed = { "ruby_lsp", "lua_ls" },
      ensure_installed = { "lua_ls", "pylsp", "ts_ls" },
      automatic_installation = true,
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.general = capabilities.general or {}
      capabilities.general.positionEncodings = { "utf-8" }
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

      -- Ruby LSP (Shopify/ruby-lsp)
      vim.lsp.config('ruby_lsp', {
        cmd = { vim.fn.expand("/Users/edgar/.bin/ruby-lsp-wrapper") },
        root_markers = { ".ruby-lsp", "Gemfile", ".git" },
        init_options = {
          formatter = "rubocop", -- or "standard" / "rubocop" if configured in your project
          linters = { "rubocop" },
        },
        settings = {
          rubyLsp = {
            enabledFeatures = {
              "codeActions",
              "diagnostics",
              "documentHighlights",
              "documentSymbols",
              "formatting",
              "hover",
              "inlayHint",
              "selectionRanges",
              "semanticHighlighting",
              "signatureHelp"
            }
          },
        },
        capabilities = capabilities,
      })
      vim.lsp.enable('ruby_lsp')

      -- Python LSP
      vim.lsp.config("pylsp", {
        cmd_env = {
          -- Strongest nudges for Python to be UTF-8:
          PYTHONUTF8 = "1",              -- Python 3.7+: enables UTF-8 mode
          PYTHONIOENCODING = "utf-8",    -- I/O encoding for stdin/stdout/stderr

          -- Locale for Linux/macOS; harmless on Windows:
          LANG = "en_US.UTF-8",
          LC_ALL = "en_US.UTF-8",
        },
        on_init = function(client)
          -- Explicitly force UTF-8 offset encoding
          client.offset_encoding = "utf-8"
          return true
        end,
        capabilities = capabilities,

        -- Optional: customize settings
        settings = {
          pylsp = {
            -- Example: Enable specific plugins
            plugins = {
              pycodestyle = { enabled = true },
              pylsp_mypy = { enabled = true },
              pylsp_black = { enabled = true, line_length = 88 },
            },
          },
        },
      })
      vim.lsp.enable("pylsp")

      -- Typescript/Javascript LSP
      vim.lsp.config("ts_ls", {
        cmd_env = {
          -- Force UTF-8 encoding for Node.js/TypeScript
          NODE_OPTIONS = "--max-old-space-size=4096",
          LANG = "en_US.UTF-8",
          LC_ALL = "en_US.UTF-8",
        },
        on_init = function(client)
          -- Explicitly force UTF-8 offset encoding
          client.offset_encoding = "utf-8"
          return true
        end,
        capabilities = capabilities,
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
            format = { enable = false }, -- prefer external formatter
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
            format = { enable = false },
          },
        },
      })
      vim.lsp.enable("ts_ls")

      -- Lua (neovim config)
      vim.lsp.config('lua_ls', {
        cmd_env = {
          -- Force UTF-8 encoding for consistent behavior
          LANG = "en_US.UTF-8",
          LC_ALL = "en_US.UTF-8",
        },
        on_init = function(client)
          -- Explicitly force UTF-8 offset encoding
          client.offset_encoding = "utf-8"
          return true
        end,
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })
      vim.lsp.enable("lua_ls")

      -- Bash LSP
      vim.lsp.config("bashls", {
        cmd = { "bash-language-server", "start" },
        cmd_env = {
          -- Force UTF-8 encoding for consistent behavior
          LANG = "en_US.UTF-8",
          LC_ALL = "en_US.UTF-8",
        },
        filetypes = { "sh", "bash" },
        on_init = function(client)
          -- Explicitly force UTF-8 offset encoding (consistent with your other configs)
          client.offset_encoding = "utf-8"
          return true
        end,
        capabilities = capabilities,
        settings = {
          bashIde = {
            -- Enable/disable shellcheck integration
            shellcheckPath = "shellcheck",
            shellcheckArguments = "",

            -- Globbing patterns for files to analyze
            globPattern = "*@(.sh|.inc|.bash|.command)",

            -- Enable/disable background analysis
            backgroundAnalysisMaxFiles = 500,

            -- Enable explainshell integration for hover documentation
            explainshellEndpoint = "",

            -- Highlight parsing errors
            highlightParsingErrors = true,
          },
        },
      })
      vim.lsp.enable("bashls")

      -- Basic LSP keymaps
      local map = vim.keymap.set
      local opts = { noremap = true, silent = true }
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { buffer = bufnr, desc = "LSP: Go to definition" }))
          map("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { buffer = bufnr, desc = "LSP: References" }))
          map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { buffer = bufnr, desc = "LSP: Hover" }))
          map("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { buffer = bufnr, desc = "LSP: Rename symbol" }))
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { buffer = bufnr, desc = "LSP: Code action" }))
          map("n", "<leader>fd", function() vim.diagnostic.open_float(nil, { scope = "line" }) end,
            vim.tbl_extend("force", opts, { buffer = bufnr, desc = "LSP: Line diagnostics" }))
        end,
      })
    end,
  },
}
