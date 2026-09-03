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
