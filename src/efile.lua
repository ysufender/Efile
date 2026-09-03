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
