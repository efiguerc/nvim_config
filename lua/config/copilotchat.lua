return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },

    config = function()
      local copilot_router = require("copilot_router")

      -- Setup router with your preferences
      copilot_router.setup({
        debug = true, -- Enable to see routing decisions
        default_model = "claude-haiku-3.5",

        -- Add custom keywords for your domain
        complexity_keywords = {
          "refactor",
          "architecture",
          "design pattern",
          "explain in detail",
          "debug",
          "optimize",
          -- Add your own:
          "security",
          "scale",
          "concurrent",
        },
      })

      local chat = require("CopilotChat")
      local select = require("CopilotChat.select")

      -- Store the current model choice
      local current_model = nil

      chat.setup({
        model = "claude-haiku-3.5", -- Default model

        -- Prompts with automatic routing
        prompts = {
          Explain = {
            prompt = "/COPILOT_EXPLAIN Write an explanation for the selected code as paragraphs of text.",
            -- This will use Sonnet due to "explain" keyword
          },

          Review = {
            prompt = "/COPILOT_REVIEW Review the selected code.",
            -- This will use Sonnet due to "review" keyword
          },

          Fix = {
            prompt = "/COPILOT_GENERATE There is a problem in this code. Rewrite the code to show it with the bug fixed.",
            -- Haiku is fine for simple fixes
          },

          Optimize = {
            prompt = "/COPILOT_GENERATE Optimize the selected code to improve performance and readability.",
            -- This will use Sonnet due to "optimize" keyword
          },

          Docs = {
            prompt = "/COPILOT_GENERATE Please add documentation comments for the selection.",
            -- Haiku is fine for docs
          },

          Tests = {
            prompt = "/COPILOT_GENERATE Please generate tests for my code.",
            -- Haiku is fine for simple tests
          },

          -- Custom prompts with explicit model preference
          DeepExplain = {
            prompt = "/COPILOT_EXPLAIN Explain in detail how this code works, including design patterns, trade-offs, and potential issues.",
            model = "claude-sonnet-4.5", -- Force Sonnet
          },

          QuickFix = {
            prompt = "/COPILOT_GENERATE Fix the syntax error.",
            model = "claude-haiku-3.5", -- Force Haiku
          },
        },

        -- Auto-select model based on context
        auto_follow_cursor = false,
        auto_insert_mode = false,

        -- Question callback to dynamically select model
        question_header = function()
          local model_name = copilot_router.get_model_display_name(
            current_model or "claude-haiku-3.5"
          )
          return "## User (" .. model_name .. ")"
        end,

        -- Window configuration
        window = {
          layout = "vertical",
          width = 0.4,
        },

        mappings = {
          complete = {
            detail = "Use @<Tab> or /<Tab> for options.",
            insert = "<Tab>",
          },
          close = {
            normal = "q",
            insert = "<C-c>",
          },
          reset = {
            normal = "<C-r>",
            insert = "<C-r>",
          },
          submit_prompt = {
            normal = "<CR>",
            insert = "<C-s>",
          },
          accept_diff = {
            normal = "<C-y>",
            insert = "<C-y>",
          },
          yank_diff = {
            normal = "gy",
          },
          show_diff = {
            normal = "gd",
          },
          show_system_prompt = {
            normal = "gp",
          },
          show_user_selection = {
            normal = "gs",
          },
        },
      })

      -- Wrapper function to inject model routing
      local function ask_with_routing(prompt, options)
        options = options or {}

        -- Get current buffer for context analysis
        local bufnr = vim.api.nvim_get_current_buf()

        -- Select model based on prompt and context
        current_model = copilot_router.select_model(
          prompt,
          bufnr,
          options.model -- Allow manual override
        )

        -- Update the model for this request
        options.model = current_model

        -- Call the original ask function
        chat.ask(prompt, options)
      end

      -- Expose wrapped function globally
      _G.copilot_ask = ask_with_routing
    end,

    keys = {
      -- Quick chat with automatic routing
      { "<leader>cc", function()
        local input = vim.fn.input("Quick Chat: ")
        if input ~= "" then
          _G.copilot_ask(input)
        end
      end, desc = "CopilotChat - Quick chat" },

      -- Visual selection chat with routing
      { "<leader>cv", function()
        local input = vim.fn.input("Ask about selection: ")
        if input ~= "" then
          _G.copilot_ask(input, {
            selection = require("CopilotChat.select").visual,
          })
        end
      end, mode = "v", desc = "CopilotChat - Visual selection" },

      -- Force Sonnet mode
      { "<leader>cs", function()
        local input = vim.fn.input("Ask Sonnet: ")
        if input ~= "" then
          _G.copilot_ask(input, { model = "claude-sonnet-4.5" })
        end
      end, desc = "CopilotChat - Force Sonnet" },

      -- Force Haiku mode
      { "<leader>ch", function()
        local input = vim.fn.input("Ask Haiku: ")
        if input ~= "" then
          _G.copilot_ask(input, { model = "claude-haiku-3.5" })
        end
      end, desc = "CopilotChat - Force Haiku" },

      -- Predefined prompts
      { "<leader>ce", "<cmd>CopilotChatExplain<cr>", desc = "CopilotChat - Explain code" },
      { "<leader>cr", "<cmd>CopilotChatReview<cr>", desc = "CopilotChat - Review code" },
      { "<leader>cf", "<cmd>CopilotChatFix<cr>", desc = "CopilotChat - Fix code" },
      { "<leader>co", "<cmd>CopilotChatOptimize<cr>", desc = "CopilotChat - Optimize code" },

      -- Toggle chat window
      { "<leader>ct", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat - Toggle" },
    },
  },
}
