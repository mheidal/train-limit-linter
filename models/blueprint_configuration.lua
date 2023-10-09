local constants = require("constants")

---@class TLLBlueprintConfiguration
---@field new_blueprint_orientation string -- add type hints to constants?
---@field snap_enabled boolean
---@field snap_direction string,
---@field snap_width number

Exports = {}

schedule_table_config = {
    new_blueprint_orientation = constants.orientations.d,
    snap_enabled = true,
    snap_direction = constants.snap_directions.horizontal,
    snap_width = 2
}

---@param config TLLBlueprintConfiguration
---@param new_orientation string
---@return TLLBlueprintConfiguration
function set_new_blueprint_orientation(config, new_orientation)
    config.new_blueprint_orientation = new_orientation
    return config
end

---@param config TLLBlueprintConfiguration
---@param new_snap_width number
---@return TLLBlueprintConfiguration
function set_snap_width(config, new_snap_width)
    config.snap_width = new_snap_width
    return config
end

---@param config TLLBlueprintConfiguration
---@return TLLBlueprintConfiguration
function toggle_snap_direction(config)
    config.snap_direction = config.snap_direction == constants.snap_directions.horizontal and constants.snap_directions.vertical or constants.snap_directions.horizontal
    return config
end

---@return TLLBlueprintConfiguration
function get_new_blueprint_configuration()
    return deep_copy(schedule_table_config)
end

Exports.get_new_blueprint_configuration = get_new_blueprint_configuration
Exports.set_new_blueprint_orientation = set_new_blueprint_orientation
Exports.set_snap_width = set_snap_width
Exports.toggle_snap_direction = toggle_snap_direction

return Exports