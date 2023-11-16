local constants = require("constants")

---@class TLLGeneralConfiguration
---@field remove_train_option string -- strings enumerated in constants.remove_train_option_enums
---@field change_remove_train_option fun(self: TLLGeneralConfiguration, new_option: string)

local TLLGeneralConfiguration = {}
local mt = { __index = TLLGeneralConfiguration }
script.register_metatable("TLLGeneralConfiguration", mt)

function TLLGeneralConfiguration.new()
    local self = {
        remove_train_option = constants.remove_train_option_enums.mark,
    }
    setmetatable(self, mt)
    return self
end

function TLLGeneralConfiguration:change_remove_train_option(new_option)
    if not constants.remove_train_option_enums[new_option] then error("No such train option") end
    self.remove_train_option = new_option
end

return TLLGeneralConfiguration