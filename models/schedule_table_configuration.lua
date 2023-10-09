Exports = {}

fuel_category_config = {
    only_current_surface = true,
    show_satisfied = true, -- satisfied when sum of train limits is 1 greater than sum of trains
    show_invalid = false, -- invalid when train limits are not set for all stations in name group
}

function toggle_current_surface(config)
    config.only_current_surface = not config.only_current_surface
end

function toggle_show_satisfied(config)
    config.show_satisfied = not config.show_satisfied
end

function toggle_show_invalid(config)
    config.show_invalid = not config.show_invalid
end

Exports.fuel_category_config = fuel_category_config
Exports.toggle_current_surface = toggle_current_surface
Exports.toggle_show_satisfied = toggle_show_satisfied
Exports.toggle_show_invalid = toggle_show_invalid

return Exports