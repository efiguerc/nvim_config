-- Model routing logic for CopilotChat
local M = {}

-- Get model display name for UI
function M.get_model_display_name(model)
  if model:match("sonnet") then
    return "🧠 Sonnet 4.5"
  elseif model:match("haiku") then
    return "⚡ Haiku 4.5"
  end
  return model
end

return M
