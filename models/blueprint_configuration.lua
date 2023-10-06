local constants = require("constants")

Exports = {}

config = {
    new_blueprint_orientation = constants.orientations.d,
    snap_enabled = true,
    snap_direction = constants.snap_directions.horizontal,
    snap_width = 2
}

function set_new_blueprint_orientation(config, new_orientation)
    config.new_blueprint_orientation = new_orientation
end

Exports.config = config
Exports.set_new_blueprint_orientation = set_new_blueprint_orientation

return Exports