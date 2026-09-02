---@class Step
---@field name         string
---@field dependencies string[]
---@field actions      string[]
local Step = {}

---@param name         string
---@param dependencies string[]
---@param actions      string[]
---@return Step
function Step.init(name, dependencies, actions)
    return {
        name = name,
        dependencies = dependencies,
        actions = actions,
    }
end

return Step
