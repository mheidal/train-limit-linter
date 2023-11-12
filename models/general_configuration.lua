---@class TLLGeneralConfiguration
---@field opinionate boolean
---@field toggle_opinionate fun(self: TLLGeneralConfiguration)

local TLLGeneralConfiguration = {}
local mt = { __index = TLLGeneralConfiguration }
script.register_metatable("TLLGeneralConfiguration", mt)

function TLLGeneralConfiguration.new()
    local self = {
        opinionate=true,
    }
    setmetatable(self, mt)
    return self
end

function TLLGeneralConfiguration:toggle_opinionate()
    self.opinionate = not self.opinionate
end

return TLLGeneralConfiguration