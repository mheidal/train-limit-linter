local constants = require("constants")

Exports = {}

fuel_category_config = {
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

function toggle_snap_direction(config)
    config.snap_direction = config.snap_direction == constants.snap_directions.horizontal and constants.snap_directions.vertical or constants.snap_directions.horizontal
    return config
end

Exports.fuel_category_config = fuel_category_config
Exports.set_new_blueprint_orientation = set_new_blueprint_orientation
Exports.set_snap_width = set_snap_width
Exports.toggle_snap_direction = toggle_snap_direction

return Exports