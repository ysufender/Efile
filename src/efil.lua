local Step = require "src.step"

---@class Map<K, V> { [K]: V }

---@class Project
---@field name  string
---@field steps Map<string, Step>
local Project = {}

---@param name  string
---@param steps Step[]
---@return Project
function Project.init(name, steps)
    ---@type Map<string, Step>
    local map = {}

    for _, step in ipairs(steps) do
        map[step.name] = step
    end

    return {
        name = name,
        steps = map,
    }
end

---@param target nil|string
---@return nil|string
function Project:build(target)
    if #self.steps == 0 then
        return "Expected at least one step."
    end

    if target == nil then
        return "Expected a target name."
    end

    local res = self:resolve(target)
    if res then
        return res
    end
end

---@private
---@param target string
---@return nil|string
function Project:resolve(target)
end

return Project
