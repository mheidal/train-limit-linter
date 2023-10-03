utils = require("utils")

Exports = {}

config = {
    add_fuel = true, -- boolean
    selected_fuel = nil, -- nil or string
    fuel_amount = 0 -- 0 to 3 stacks of selected_fuel
}

function toggle_add_fuel(config)
    config.add_fuel = not config.add_fuel

    return config
end

function change_selected_fuel(config, selected_item)
    -- If the current config.selected_fuel == selected_item, deselect it
    if config.selected_fuel == selected_item then
        config.selected_fuel = nil
    else
        config.selected_fuel = selected_item
    end

    return config
end

function set_fuel_amount(config, amount)
    config.fuel_amount = amount
    return config
end

Exports.config = config
Exports.toggle_add_fuel = toggle_add_fuel
Exports.change_selected_fuel = change_selected_fuel
Exports.set_fuel_amount = set_fuel_amount

return Exports