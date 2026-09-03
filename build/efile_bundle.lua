do
local _ENV = _ENV
package.preload[ "src.build_system.args" ] = function( ... ) local arg = _G.arg;
---@class Map<K, V>: { [K]: V }

---@class Args
---@field args Map<string, any>
local Args = {}

---@generic T
---@param name string
---@return T
function Args:get(name)
    return self.args[name]
end

return Args
end
end

do
local _ENV = _ENV
package.preload[ "src.build_system.project" ] = function( ... ) local arg = _G.arg;
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
end
end

do
local _ENV = _ENV
package.preload[ "src.build_system.step" ] = function( ... ) local arg = _G.arg;
---@module "src.project"

---@class Step
---@field name         string
---@field dependencies Dependency[]
---@field actions      Action[]
local Step = {}

---@alias Command string
---@alias Script fun(): string?

---@alias Action Command|Script

---@alias Complex fun(project: Project):string?

---@alias Dependency Complex|string

---@param name         string
---@return Step
function Step.init(name)
    local obj = {
        name = name,
        dependencies = { },
        actions = { },
    }
    setmetatable(obj, { __index = Step })
    return obj
end

---@param name string
---@return Step
function Step:dependOn(name)
    table.insert(self.dependencies, name)
    return self
end

---@param action Action
---@return Step
function Step:action(action)
    table.insert(self.actions, action)
    return self
end

---@param project Project
---@return string?
function Step:build(project)
    for _, dependency in ipairs(self.dependencies) do
        ---@type string?
        local err

        if type(dependency) == "string" then
            err = project:build(dependency)
        else
            err = dependency(project)
        end

        if err then
            return err.."\n....Required from '"..self.name.."'"
        end
    end

    for _, action in ipairs(self.actions) do
        ---@type string?
        local err

        if type(action) == "string" then
            err = self.exec(action)
        else
            err = action()
        end

        if err then
            return err.."\n....Required from '"..self.name.."'"
        end
    end
end

---@private
---@param command string
---@return string?
function Step.exec(command)
    print("> Executing command '"..command.."'")
    local output = io.popen(command.." 2>&1")

    if output == nil then
        return "Failed to execute command."
    end

    for line in output:lines() do
        print(">> "..line)
    end
    print()

    local _, _, code = output:close()

    if code ~= 0 then
        return ">>> Command exited with code '"..tostring(code).."'"
    end
end

return Step
end
end

local Project = require "src.build_system.project"
local Step = require "src.build_system.step"

---@class Efile
---@field Project Project
---@field Step    Step
local Efile = {
    Project = Project,
    Step = Step,
}

return Efile
