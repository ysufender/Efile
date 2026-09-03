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
    print(">> is_modified: " .. subpath .. " mtime=" .. tostring(current_mtime))

    if not current_mtime then
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
        print(">> " .. subpath .. ": no cache, returning true")
        return true
    end

    local cached_mtime = tonumber(f:read("*a"))
    f:close()
    print(">> " .. subpath .. ": cached=" .. tostring(cached_mtime) .. " current=" .. tostring(current_mtime) .. " modified=" .. tostring(current_mtime > cached_mtime))

    if current_mtime > cached_mtime then
        local out = io.open(cache_path, "w")
        if not out then return true end
        out:write(tostring(current_mtime))
        out:close()
        return true
    end

    return false
end

function Project:resolve(target, accumulator, to_build)
    accumulator = accumulator or { }
    to_build = to_build or { }

    local step = self.steps[target]

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

    print(">> resolve: " .. target .. " will_build=" .. tostring(will_build))

    if will_build then
        ---@cast to_build table
        table.insert(to_build, target)
    end
end
return Project
