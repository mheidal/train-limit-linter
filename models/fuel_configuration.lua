utils = require("utils")

---@class TLLFuelConfiguration
---@field add_fuel boolean
---@field fuel_category_configurations TLLFuelCategoryConfiguration[]

---@class TLLFuelCategoryConfiguration
---@field selected_fuel string?
---@field fuel_amount number

---@class TLLFuelCategoryData
---@field locomotives_fuel_categories table<string, string[]>
---@field fuel_categories_and_fuels table<string, string[]>

Exports = {}

-- Fuel category configuration

---@type TLLFuelCategoryConfiguration
fuel_category_config = {
    selected_fuel = nil, -- nil or string
    fuel_amount = 0 -- 0 to 3 stacks of selected_fuel
}

---@param fuel_category_config TLLFuelCategoryConfiguration
---@param selected_item string
---@return TLLFuelCategoryConfiguration
function change_selected_fuel(fuel_category_config, selected_item)
    -- If the current config.selected_fuel == selected_item, deselect it
    if fuel_category_config.selected_fuel == selected_item then
        fuel_category_config.selected_fuel = nil
    else
        fuel_category_config.selected_fuel = selected_item
    end

    return fuel_category_config
end

---@param fuel_category_config TLLFuelCategoryConfiguration
---@param amount number
---@return TLLFuelCategoryConfiguration
function set_fuel_amount(fuel_category_config, amount)
    fuel_category_config.fuel_amount = amount
    return fuel_category_config
end

---@return TLLFuelCategoryConfiguration
function get_fuel_category_configuration()
    return deep_copy(fuel_category_config)
end

-- Fuel configuration

---@type TLLFuelConfiguration
fuel_config = {
    add_fuel = true,
    fuel_category_configurations = {}
}

---@param fuel_config TLLFuelConfiguration
---@return TLLFuelConfiguration
function toggle_add_fuel(fuel_config)
    fuel_config.add_fuel = not fuel_config.add_fuel
    return fuel_config
end

Exports.get_fuel_category_configuration = get_fuel_category_configuration
Exports.change_selected_fuel = change_selected_fuel
Exports.set_fuel_amount = set_fuel_amount

Exports.toggle_add_fuel = toggle_add_fuel

return Exports