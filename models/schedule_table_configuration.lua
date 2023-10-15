---@class TLLScheduleTableConfiguration
---@field only_current_surface boolean
---@field show_satisfied boolean
---@field show_invalid boolean
---@field new fun(self: TLLScheduleTableConfiguration): TLLScheduleTableConfiguration
---@field toggle_current_surface fun(self: TLLScheduleTableConfiguration)
---@field toggle_show_satisfied fun(self: TLLScheduleTableConfiguration)
---@field toggle_show_invalid fun(self: TLLScheduleTableConfiguration)

---@class TLLScheduleTableConfiguration
local TLLScheduleTableConfiguration = {}
local mt = { __index = TLLScheduleTableConfiguration }
script.register_metatable("TLLScheduleTableConfiguration", mt)

function TLLScheduleTableConfiguration.new()
    local self = {
        only_current_surface = true,
        show_satisfied = true, -- satisfied when sum of train limits is 1 greater than sum of trains
        show_invalid = false, -- invalid when train limits are not set for all stations in name group
    }
    setmetatable(self, mt)
    return self
end

function TLLScheduleTableConfiguration:toggle_current_surface()
    self.only_current_surface = not self.only_current_surface
end

function TLLScheduleTableConfiguration:toggle_show_satisfied()
    self.show_satisfied = not self.show_satisfied
end

function TLLScheduleTableConfiguration:toggle_show_invalid()
    self.show_invalid = not self.show_invalid
end

return TLLScheduleTableConfiguration
