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
    os.execute("mkdir -p build/.cache/")

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

    local to_build = { }
    local err = self:resolve(target, to_build)
    if err then return err end
    for _, step in ipairs(to_build or { }) do
        err = self.steps[step]:build()
        if err then return err end
    end
end

---@param path string
---@return integer?
local function get_mtime(path)
    local f = io.popen('stat -c "%Y" "' .. path .. '"')
    if not f then return nil end
    local mtime = tonumber(f:read("*a"))
    f:close()
    return mtime
end

local function is_modified(subpath)
    local cache_path = "build/.cache/" .. subpath

    local current_mtime = get_mtime(subpath)

    if not current_mtime then
        -- Source file doesn't exist, create it and return true
        os.execute('mkdir -p "' .. subpath:match("^(.*)/[^/]+$") .. '"')
        io.open(subpath, "w"):close()
        current_mtime = get_mtime(subpath)
    end

    local f = io.open(cache_path, "r")
    if not f then
        os.execute('mkdir -p "' .. cache_path:match("^(.*)/[^/]+$") .. '"')
        local out = io.open(cache_path, "w")
        if not out then return true end
        out:write(tostring(current_mtime))
        out:close()
        return true
    end

    local cached_mtime = tonumber(f:read("*a"))
    f:close()

    if current_mtime > cached_mtime then
        local out = io.open(cache_path, "w")
        if not out then return true end
        out:write(tostring(current_mtime))
        out:close()
        return true
    end

    return false
end

---@private
---@param target      string
---@param to_build    string[]
---@param accumulator Map<string, string>?
---@return string?
function Project:resolve(target, to_build, accumulator)
    accumulator = accumulator or { }

    local step = self.steps[target];

    if accumulator[target] then return "Target '"..target.."' depends on itself." end
    if step == nil then return "Unknown step '"..target.."'." end

    local will_build, err = false, nil
    accumulator[target] = target

    for _, dependency in ipairs(step.dependencies) do
        if type(dependency) == "string" then
            local count = #to_build
            err = self:resolve(dependency, accumulator, to_build)
            if err then return err.."\n....Required from '"..target.."'" end

            if count ~= #to_build then
                will_build = true
            end
        else
            if is_modified(dependency.file) then
                will_build = true
            end
        end
    end

    if will_build then
        ---@cast to_build table
        table.insert(to_build, target)
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
---@field prebuild     Action[]
local Step = {}

---@alias Command string
---@alias Script fun(): string?

---@alias Action Command|Script

---@class Complex
---@field file string

---@alias Dependency Complex|string

---@param name         string
---@return Step
function Step.init(name)
    local obj = {
        name = name,
        dependencies = { },
        actions = { },
        prebuild = { },
    }
    setmetatable(obj, { __index = Step })
    return obj
end

---@param dependency Dependency
---@return Step
function Step:dependOn(dependency)
    table.insert(self.dependencies, dependency)
    return self
end

---@param action Action
---@return Step
function Step:action(action)
    table.insert(self.actions, action)
    return self
end

---@param action Action
---@return Step
function Step:pre(action)
    table.insert(self.prebuild, action)
    return self
end

---@return string?
function Step:build()
    for _, prebuild in ipairs(self.prebuild) do
        local err = self:execute_action(prebuild)
        if err then return err end
    end

    for _, action in ipairs(self.actions) do
        local err = self:execute_action(action)
        if err then return err end
    end
end

---@private
---@param action Action
---@return string?
function Step:execute_action(action)
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
