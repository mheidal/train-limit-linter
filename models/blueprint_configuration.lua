local constants = require("constants")

---@class TLLBlueprintConfiguration
---@field new_blueprint_orientation number -- add type hints to constants?
---@field snap_enabled boolean
---@field snap_direction string,
---@field snap_width number
---@field set_new_blueprint_orientation fun(self: TLLBlueprintConfiguration, new_orientation: number)
---@field set_snap_width fun(self: TLLBlueprintConfiguration, new_snap_width: number)
---@field toggle_snap_direction fun(self: TLLBlueprintConfiguration)

Exports = {}

blueprint_config = {
    new_blueprint_orientation = constants.orientations.d,
    snap_enabled = true,
    snap_direction = constants.snap_directions.horizontal,
    snap_width = 2
}

---@param new_orientation number
function blueprint_config:set_new_blueprint_orientation(new_orientation)
    self.new_blueprint_orientation = new_orientation
end

---@param new_snap_width number
function blueprint_config:set_snap_width(new_snap_width)
    self.snap_width = new_snap_width
end

function blueprint_config:toggle_snap_direction()
    self.snap_direction = self.snap_direction == constants.snap_directions.horizontal and constants.snap_directions.vertical or constants.snap_directions.horizontal
end

---@return TLLBlueprintConfiguration
function get_new_blueprint_configuration()
    return deep_copy(blueprint_config)
end

Exports.get_new_blueprint_configuration = get_new_blueprint_configuration

return Exports