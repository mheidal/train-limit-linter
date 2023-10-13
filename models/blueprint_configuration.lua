local constants = require("constants")

---@class TLLBlueprintConfiguration
---@field new_blueprint_orientation number -- add type hints to constants?
---@field snap_enabled boolean
---@field snap_direction string,
---@field snap_width number
---@field new fun(self: TLLBlueprintConfiguration): TLLBlueprintConfiguration
---@field set_new_blueprint_orientation fun(self: TLLBlueprintConfiguration, new_orientation: number)
---@field set_snap_width fun(self: TLLBlueprintConfiguration, new_snap_width: number)
---@field toggle_snap_direction fun(self: TLLBlueprintConfiguration)
---@field toggle_blueprint_snap fun(self: TLLBlueprintConfiguration)

Exports = {}

TLLBlueprintConfiguration = {}

function TLLBlueprintConfiguration:new()
    local new_object = {
        new_blueprint_orientation = constants.orientations.d,
        snap_enabled = true,
        snap_direction = constants.snap_directions.horizontal,
        snap_width = 2
    }
    setmetatable(new_object, self)
    self.__index = self
    return new_object
end

---@param new_orientation number
function TLLBlueprintConfiguration:set_new_blueprint_orientation(new_orientation)
    self.new_blueprint_orientation = new_orientation
end

---@param new_snap_width number
function TLLBlueprintConfiguration:set_snap_width(new_snap_width)
    self.snap_width = new_snap_width
end

function TLLBlueprintConfiguration:toggle_snap_direction()
    self.snap_direction = self.snap_direction == constants.snap_directions.horizontal and constants.snap_directions.vertical or constants.snap_directions.horizontal
end

function TLLBlueprintConfiguration:toggle_blueprint_snap()
    self.snap_enabled = not self.snap_enabled
end

Exports.TLLBlueprintConfiguration = TLLBlueprintConfiguration

return Exports