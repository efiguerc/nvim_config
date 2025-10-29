return {
  ---------------------------------------------------------
  -- GitHub Copilot Chat (ask questions, reviews, fixes)
  ---------------------------------------------------------
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    -- If you want the bleeding edge features, you can use: branch = "canary",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "zbirenbaum/copilot.lua",
      "nvim-telescope/telescope.nvim", -- optional but recommended for prompt picker
    },
    config = function()
      local copilot_router = require("copilot_router")

      local chat = require("CopilotChat")

      -- Store the current model choice
      local current_model = nil

      chat.setup({
        debug = false,

        -- Default model
        model = "claude-haiku-4.5",

        -- Customize the chat window
        window = {
          layout = 'vertical',      -- 'vertical', 'horizontal', 'float'
          width = 0.4,              -- 30% of screen width
          relative = "editor",
          row = 2,
          col = 2,
          border = "rounded",
        },

        -- Question callback to dynamically select model
        question_header = function()
          local model_name = copilot_router.get_model_display_name(
            current_model or "claude-haiku-4.5"
          )
          return "## User (" .. model_name .. ")"
        end,

        answer_header = "  Copilot ",
        -- Rails-aware prompts you can reuse via the Telescope picker or keymaps below
        prompts = {
          ExplainRails = {
            prompt = "Explain what this Ruby on Rails code does, covering models, controllers, views, routes, callbacks, validations, and queries if relevant. Be concise but thorough.",
          },
          ReviewRails = {
            prompt = "Review the selected Ruby/Rails code. Identify potential bugs, security issues (SQL injection, mass assignment, CSRF), N+1 queries, performance problems, and deviations from Rails conventions. Provide concrete, actionable suggestions with improved code.",
          },
          AddRSpecTests = {
            prompt = "Write RSpec tests for the selected Ruby/Rails code. Use factories if applicable, structure with describe/context/it, and focus on behavior and edge cases. Only output the spec code.",
          },
          RefactorRails = {
            prompt = "Refactor the selected Ruby/Rails code for readability, maintainability, and performance. Prefer idiomatic Ruby and Rails conventions. Provide the refactored code and a brief rationale.",
          },
          ReviewGitDiff = {
            prompt = "Perform a thorough code review of the following Git diff. Focus on correctness, tests, security, performance, and Rails conventions. Provide line-referenced comments and suggested patches.",
          },
        },
      })

      local select = require("CopilotChat.select")

      -- Convenient keymaps for interacting with Copilot Chat
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
      end

      -- Toggle chat window
      map("n", "<leader>ct", chat.toggle, "Copilot Chat: Toggle")

      -- Explain selection (supports normal/visual)
      map({ "n", "v" }, "<leader>ce", function()
        chat.ask(
          -- "Explain the selected code. Highlight key Ruby/Rails details and any subtle behaviors.",
          "Explain the selected code. Highlight key details and any subtle behaviors.",
          { selection = select.visual }
        )
      end, "Copilot Chat: Explain selection")

      -- Fix issues in selection
      map({ "n", "v" }, "<leader>cf", function()
        chat.ask(
          "Find and fix issues in the selected code. Provide improved code and brief explanations.",
          { selection = select.visual }
        )
      end, "Copilot Chat: Fix selection")

      -- Generate RSpec tests for selection
      map({ "n", "v" }, "<leader>ctt", function()
        chat.ask(
          "Write RSpec tests for the selected Ruby/Rails code. Use factories where appropriate and only output the spec content.",
          { selection = select.visual }
        )
      end, "Copilot Chat: Generate RSpec tests")

      -- Review current buffer
      map("n", "<leader>cR", function()
        chat.ask(
          "Review the current buffer. Identify bugs, security issues (SQL injection, mass assignment, CSRF), N+1 queries, performance problems, and deviations from Ruby/Rails idioms. Provide actionable suggestions and patches.",
          { selection = select.buffer }
        )
      end, "Copilot Chat: Review buffer")

      -- Review current Git diff (staged/unstaged changes)
      map("n", "<leader>cD", function()
        chat.ask(
          "Perform a thorough code review for the following Git diff. Provide line-referenced comments and suggested patches. Focus on correctness, tests, security, performance, and Rails conventions.",
          { selection = select.gitdiff }
        )
      end, "Copilot Chat: Review Git diff")

      -- Refactor selection for performance
      map("v", "<leader>rr", function()
        chat.ask(
          "Perform a thorough code refactor for the current selection. Provide line-referenced comments. Focus on correctness, performance, and programing language conventions.",
          { selection = select.visual }
        )
      end, "Copilot Chat: Refactor selection for performance")

      -- Optional: prompt picker via Telescope (choose from configured prompts)
      local ok, telescope_integration = pcall(require, "CopilotChat.integrations.telescope")
      if ok then
        map({ "n", "v" }, "<leader>cq", telescope_integration.pick, "Copilot Chat: Prompt picker")
      end

      -- User commands for quick access in command-line
      vim.api.nvim_create_user_command("CopilotReviewBuffer", function()
        chat.ask(
          "Review the current buffer for potential bugs, security issues (SQL injection, mass assignment, CSRF), N+1 queries, performance problems, and Rails conventions. Provide actionable suggestions and patches.",
          { selection = select.buffer }
        )
      end, {})

      vim.api.nvim_create_user_command("CopilotReviewDiff", function()
        chat.ask(
          "Review the following Git diff and provide feedback with suggested code changes. Focus on tests, security, performance, and Rails best practices.",
          { selection = select.gitdiff }
        )
      end, {})

      vim.api.nvim_create_user_command("CopilotExplain", function()
        chat.ask("Explain the selected code with Ruby/Rails context.", { selection = select.visual })
      end, { range = true })
    end,
  },
}
