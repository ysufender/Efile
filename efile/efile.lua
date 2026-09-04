local Project = require "efile.build_system.project"
local Step = require "efile.build_system.step"

---@enum PLATFORM
local PLATFORM = {
    WIN32 = 0,
    UNIX = 1,
}

---@class Efile
---@field Project  Project
---@field Step     Step
---@field Platform PLATFORM
local Efile = {
    Project = Project,
    Step = Step,
    PLATFORM = PLATFORM,

    platform = (package.config:sub(1, 1) == '/') and PLATFORM.UNIX or PLATFORM.WIN32
}

return Efile
