---@class TLLScheduleTableConfiguration
---@field show_all_surfaces boolean
---@field show_satisfied boolean
---@field show_not_set boolean
---@field show_dynamic boolean
---@field show_single_station_schedules boolean
---@field new fun(): TLLScheduleTableConfiguration
---@field toggle_show_all_surfaces fun(self: TLLScheduleTableConfiguration)
---@field toggle_show_satisfied fun(self: TLLScheduleTableConfiguration)
---@field toggle_show_not_set fun(self: TLLScheduleTableConfiguration)
---@field toggle_show_dynamic fun(self: TLLScheduleTableConfiguration)
---@field toggle_show_single_station_schedules fun(self: TLLScheduleTableConfiguration)

---@class TLLScheduleTableConfiguration
local TLLScheduleTableConfiguration = {}
local mt = { __index = TLLScheduleTableConfiguration }
script.register_metatable("TLLScheduleTableConfiguration", mt)

function TLLScheduleTableConfiguration.new()
    local self = {
        show_all_surfaces = false,
        show_satisfied = false, -- satisfied when sum of train limits is 1 greater than sum of trains
        show_not_set = false,
        show_dynamic = false,
        show_single_station_schedules = false,
    }
    setmetatable(self, mt)
    return self
end

function TLLScheduleTableConfiguration:toggle_show_all_surfaces()
    self.show_all_surfaces = not self.show_all_surfaces
end

function TLLScheduleTableConfiguration:toggle_show_satisfied()
    self.show_satisfied = not self.show_satisfied
end

function TLLScheduleTableConfiguration:toggle_show_not_set()
    self.show_not_set = not self.show_not_set
end

function TLLScheduleTableConfiguration:toggle_show_dynamic()
    self.show_dynamic = not self.show_dynamic
end

function TLLScheduleTableConfiguration:toggle_show_single_station_schedules()
    self.show_single_station_schedules = not self.show_single_station_schedules
end

return TLLScheduleTableConfiguration
