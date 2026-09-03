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
