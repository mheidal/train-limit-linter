local constants = require("constants")

---@class TLLBlueprintConfiguration
---@field new_blueprint_orientation number -- add type hints to constants?
---@field snap_enabled boolean
---@field snap_direction string,
---@field snap_width number
---@field new fun(): TLLBlueprintConfiguration
---@field set_new_blueprint_orientation fun(self: TLLBlueprintConfiguration, new_orientation: number)
---@field set_snap_width fun(self: TLLBlueprintConfiguration, new_snap_width: number)
---@field toggle_snap_direction fun(self: TLLBlueprintConfiguration)
---@field set_snap_direction fun(self: TLLBlueprintConfiguration, new_snap_direction: string)
---@field toggle_blueprint_snap fun(self: TLLBlueprintConfiguration)

local TLLBlueprintConfiguration = {}
local mt = { __index = TLLBlueprintConfiguration }
script.register_metatable("TLLBlueprintConfiguration", mt)

function TLLBlueprintConfiguration.new()
    local self = {
        new_blueprint_orientation = constants.orientations.d,
        snap_enabled = true,
        snap_direction = constants.snap_directions.horizontal,
        snap_width = 2
    }
    setmetatable(self, mt)
    return self
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

---@param new_snap_direction string from constants.snap_directions
function TLLBlueprintConfiguration:set_snap_direction(new_snap_direction)
    self.snap_direction = new_snap_direction
end

function TLLBlueprintConfiguration:toggle_blueprint_snap()
    self.snap_enabled = not self.snap_enabled
end

return TLLBlueprintConfiguration
