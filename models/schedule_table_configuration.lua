---@class TLLScheduleTableConfiguration
---@field only_current_surface boolean
---@field show_satisfied boolean
---@field show_invalid boolean

Exports = {}

schedule_table_config = {
    only_current_surface = true,
    show_satisfied = true, -- satisfied when sum of train limits is 1 greater than sum of trains
    show_invalid = false, -- invalid when train limits are not set for all stations in name group
}

---@param config TLLScheduleTableConfiguration
---@return TLLScheduleTableConfiguration
function toggle_current_surface(config)
    config.only_current_surface = not config.only_current_surface
    return config
end

---@param config TLLScheduleTableConfiguration
---@return TLLScheduleTableConfiguration
function toggle_show_satisfied(config)
    config.show_satisfied = not config.show_satisfied
    return config
end

---@param config TLLScheduleTableConfiguration
---@return TLLScheduleTableConfiguration
function toggle_show_invalid(config)
    config.show_invalid = not config.show_invalid
    return config
end

---@return TLLScheduleTableConfiguration
function get_new_schedule_table_configuration()
    return deep_copy(schedule_table_config)
end

Exports.get_new_schedule_table_configuration = get_new_schedule_table_configuration
Exports.toggle_current_surface = toggle_current_surface
Exports.toggle_show_satisfied = toggle_show_satisfied
Exports.toggle_show_invalid = toggle_show_invalid

return Exports