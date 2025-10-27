-- Model routing logic for CopilotChat
local M = {}

-- Configuration
M.config = {
  -- Default model
  default_model = "claude-haiku-3.5",

  -- Model definitions
  models = {
    haiku = "claude-haiku-3.5",
    sonnet = "claude-sonnet-4.5",
  },

  -- Complexity indicators that trigger Sonnet
  complexity_keywords = {
    "refactor",
    "architecture",
    "design pattern",
    "explain in detail",
    "debug",
    "optimize",
    "performance",
    "analyze",
    "review",
    "complex",
    "algorithm",
    "structure",
    "trade[-]?off",
    "multi[-]?step",
    "comprehensive",
    "in depth",
    "deep dive",
  },

  -- Token thresholds
  thresholds = {
    -- Prompts longer than this may benefit from Sonnet
    prompt_length = 500,

    -- Context size that suggests complex task
    context_lines = 50,
  },

  -- Enable debug logging
  debug = false,
}

-- Setup function to override defaults
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

-- Analyze prompt complexity
local function analyze_prompt_complexity(prompt)
  local score = 0
  local reasons = {}

  if not prompt or prompt == "" then
    return score, reasons
  end

  local lower_prompt = prompt:lower()

  -- Check for complexity keywords
  for _, keyword in ipairs(M.config.complexity_keywords) do
    if lower_prompt:match(keyword) then
      score = score + 10
      table.insert(reasons, "keyword: " .. keyword)
    end
  end

  -- Check prompt length
  if #prompt > M.config.thresholds.prompt_length then
    score = score + 5
    table.insert(reasons, "long prompt (" .. #prompt .. " chars)")
  end

  -- Check for question words indicating deep inquiry
  local deep_questions = { "why", "how does", "what are the" }
  for _, q in ipairs(deep_questions) do
    if lower_prompt:match(q) then
      score = score + 3
      table.insert(reasons, "deep question: " .. q)
    end
  end

  -- Check for code block requests
  if lower_prompt:match("implement") or lower_prompt:match("create") then
    score = score + 5
    table.insert(reasons, "implementation request")
  end

  return score, reasons
end

-- Analyze context complexity
local function analyze_context_complexity(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local score = 0
  local reasons = {}

  -- Get buffer line count
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  if line_count > M.config.thresholds.context_lines then
    score = score + 5
    table.insert(reasons, "large context (" .. line_count .. " lines)")
  end

  -- Check if multiple files are involved (via visual selection across buffers)
  -- This would require integration with CopilotChat's context system

  return score, reasons
end

-- Main routing decision function
function M.select_model(prompt, context_bufnr, manual_override)
  -- Handle manual override
  if manual_override then
    if M.config.debug then
      vim.notify(
        "Model manually overridden to: " .. manual_override,
        vim.log.levels.INFO
      )
    end
    return manual_override
  end

  -- Analyze complexity
  local prompt_score, prompt_reasons = analyze_prompt_complexity(prompt)
  local context_score, context_reasons = analyze_context_complexity(context_bufnr)
  local total_score = prompt_score + context_score

  -- Decision threshold (adjust based on your preferences)
  local sonnet_threshold = 15

  local selected_model
  if total_score >= sonnet_threshold then
    selected_model = M.config.models.sonnet
  else
    selected_model = M.config.models.haiku
  end

  -- Debug logging
  if M.config.debug then
    local all_reasons = vim.list_extend(prompt_reasons, context_reasons)
    vim.notify(
      string.format(
        "Model Router:\nScore: %d (threshold: %d)\nModel: %s\nReasons: %s",
        total_score,
        sonnet_threshold,
        selected_model,
        table.concat(all_reasons, ", ")
      ),
      vim.log.levels.INFO
    )
  end

  return selected_model
end

-- Get model display name for UI
function M.get_model_display_name(model)
  if model:match("sonnet") then
    return "🧠 Sonnet 4.5"
  elseif model:match("haiku") then
    return "⚡ Haiku 3.5"
  end
  return model
end

return M
