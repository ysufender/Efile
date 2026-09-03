---@module "src.step"

---@class Map<K, V>: { [K]: V }

---@class Project
---@field name  string
---@field steps Map<string, Step>
local Project = { }

---@param name  string
---@return Project
function Project.init(name)
    local obj = {
        name = name,
        steps = { },
    }

    setmetatable(obj, { __index = Project })
    return obj
end

---@param self   string|Project
---@param step   Step
function Project.step(self, step)
    if type(self) == "string" then
        return self.."\n....While adding step '"..step.name.."'"
    else
        if self.steps[step.name] then
            return "Duplicate step '"..step.name.."'"
        else
            self.steps[step.name] = step
            return self
        end
    end
end

---@param self string|Project
---@param target string
---@return string?
function Project.build(self, target)
    if type(self) == "string" then
        return self.."\n\nBuild failed."
    end

    if next(self.steps) == nil then return "No steps to run" end
    if self.steps[target] == nil then return "Unknown step" end

    local err = self:resolve(target)
    if err then return err end
    return self.steps[target]:build(self)
end

---@private
---@param target      string
---@param accumulator Map<string, string>?
---@return string?
function Project:resolve(target, accumulator)
    accumulator = accumulator or { }

    if accumulator[target] then
        return "Target '"..target.."' depends on itself."
    end

    local step = self.steps[target];

    if step == nil then
        return "Unknown step '"..target.."'."
    end

    for _, dependency in ipairs(step.dependencies) do
        if type(dependency) == "string" then
            accumulator[target] = target
            local err = self:resolve(dependency, accumulator)
            if err then return err.."\n....Required from '"..target.."'" end
        end
    end
end

return Project
