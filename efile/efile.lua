local Project = require "efile.build_system.project"
local Step = require "efile.build_system.step"

---@class Efile
---@field Project Project
---@field Step    Step
local Efile = {
    Project = Project,
    Step = Step,
}

return Efile
