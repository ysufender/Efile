---@module "efile.project"

---@class Step
---@field name         string
---@field dependencies Dependency[]
---@field actions      Action[]
---@field _prebuild     Action[]
---@field options      Options
local Step = {}

---@alias Command string
---@alias Script fun(): string?

---@class Options
---@field always_run boolean

---@alias Action Command|Script

---@class Complex
---@field file string

---@alias Dependency (Complex)|(string)|(DependencyList)
---@alias DependencyList Dependency[]

---@param name    string
---@param options Options?
---@return Step
function Step.init(name, options)
    local obj = {
        name = name,
        dependencies = { },
        actions = { },
        _prebuild = { },
        options = options or {
            always_run = false
        }
    }
    setmetatable(obj, { __index = Step })
    return obj
end

---@param dependency string
---@return Step
function Step:dependOnStep(dependency)
    table.insert(self.dependencies, dependency)
    return self
end

---@param files string[]
---@return Step
function Step:dependOnSteps(files)
    for _, file in ipairs(files) do
        table.insert(self.dependencies, file)
    end

    return self
end

---@param dependency string
---@return Step
function Step:dependOnFile(dependency)
    table.insert(self.dependencies, { file = dependency })
    return self
end

---@param files string[]
---@return Step
function Step:dependOnFiles(files)
    for _, file in ipairs(files) do
        table.insert(self.dependencies, { file = file })
    end

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
    table.insert(self._prebuild, action)
    return self
end

---@nodiscard
---@return string?
function Step:build()
    for _, action in ipairs(self.actions) do
        local err = self:execute_action(action)
        if err then return err end
    end
end

---@nodiscard
---@return string?
function Step:prebuild()
    for _, _prebuild in ipairs(self._prebuild) do
        local err = self:execute_action(_prebuild)
        if err then return err end
    end
end

---@private
---@nodiscard
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
---@nodiscard
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
