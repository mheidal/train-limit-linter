local constants = require("constants")

---@class TLLGeneralConfiguration
---@field remove_train_option string -- strings enumerated in constants.remove_train_option_enums
---@field ignore_stations_with_dynamic_limits boolean
---@field change_remove_train_option fun(self: TLLGeneralConfiguration, new_option: string)
---@field toggle_ignore_stations_with_dynamic_limits fun(self: TLLGeneralConfiguration)

local TLLGeneralConfiguration = {}
local mt = { __index = TLLGeneralConfiguration }
script.register_metatable("TLLGeneralConfiguration", mt)

function TLLGeneralConfiguration.new()
    local self = {
        remove_train_option = constants.remove_train_option_enums.mark,
        ignore_stations_with_dynamic_limits = false,
    }
    setmetatable(self, mt)
    return self
end

function TLLGeneralConfiguration:change_remove_train_option(new_option)
    if not constants.remove_train_option_enums[new_option] then error("No such train option") end
    self.remove_train_option = new_option
end

function TLLGeneralConfiguration:toggle_ignore_stations_with_dynamic_limits(new_option)
    self.ignore_stations_with_dynamic_limits = not self.ignore_stations_with_dynamic_limits
end

return TLLGeneralConfiguration