---@class TLLGeneralConfiguration

local TLLGeneralConfiguration = {}
local mt = { __index = TLLGeneralConfiguration }
script.register_metatable("TLLGeneralConfiguration", mt)

function TLLGeneralConfiguration.new()
    local self = {
    }
    setmetatable(self, mt)
    return self
end

return TLLGeneralConfiguration