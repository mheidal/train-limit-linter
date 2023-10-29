---@class TLLOtherModConfiguration
---@field space_exploration_combine_orbit boolean
---@field new fun(): TLLOtherModConfiguration
---@field space_exploration_toggle_combine_orbit fun(self: TLLOtherModConfiguration)

local TLLOtherModConfiguration = {}
local mt = { __index = TLLOtherModConfiguration }
script.register_metatable("TLLOtherModConfiguration", mt)

function TLLOtherModConfiguration.new()
    local self = {
        space_exploration_combine_orbit = false,
    }
    setmetatable(self, mt)
    return self
end

return TLLOtherModConfiguration