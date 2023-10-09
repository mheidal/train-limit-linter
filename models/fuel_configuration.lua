utils = require("utils")

---@class TLLFuelConfiguration
---@field add_fuel boolean
---@field fuel_category_configurations table<string, TLLFuelCategoryConfiguration>
---@field toggle_add_fuel fun(self: TLLFuelConfiguration)
---@field add_fuel_category_config fun(self: TLLFuelConfiguration, fuel_category: string)

---@class TLLFuelCategoryConfiguration
---@field selected_fuel string?
---@field fuel_amount number
---@field change_selected_fuel fun(self: TLLFuelCategoryConfiguration, string)
---@field set_fuel_amount fun(self: TLLFuelCategoryConfiguration, number)

Exports = {}

-- Fuel category configuration

fuel_category_config = {
    selected_fuel = nil, -- nil or string
    fuel_amount = 0 -- 0 to 3 stacks of selected_fuel
}

---@param selected_item string
function fuel_category_config:change_selected_fuel(selected_item)
    -- If the current config.selected_fuel == selected_item, deselect it
    if self.selected_fuel == selected_item then
        self.selected_fuel = nil
    else
        self.selected_fuel = selected_item
    end
end

---@param amount number
function fuel_category_config:set_fuel_amount(amount)
    self.fuel_amount = amount
end

---@return TLLFuelCategoryConfiguration
function get_new_fuel_category_configuration()
    return deep_copy(fuel_category_config)
end

-- Fuel configuration

fuel_config = {
    add_fuel = true,
    fuel_category_configurations = {}
}

function fuel_config:toggle_add_fuel()
    self.add_fuel = not self.add_fuel
end

---@param fuel_category string
function fuel_config:add_fuel_category_config(fuel_category)
    self.fuel_category_configurations[fuel_category] = get_new_fuel_category_configuration()
end

---@return TLLFuelConfiguration
function get_new_fuel_configuration()
    return deep_copy(fuel_config)
end

Exports.get_new_fuel_configuration = get_new_fuel_configuration

return Exports