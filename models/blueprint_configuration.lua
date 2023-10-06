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
    return config
end

function set_snap_width(config, new_snap_width)
    config.snap_width = new_snap_width
    return config
end

Exports.config = config
Exports.set_new_blueprint_orientation = set_new_blueprint_orientation
Exports.set_snap_width = set_snap_width

return Exports