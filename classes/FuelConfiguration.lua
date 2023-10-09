---@class TLLFuelConfiguration
---@field add_fuel boolean
---@field fuel_category_configurations TLLFuelCategoryConfiguration[]

---@class TLLFuelCategoryConfiguration
---@field selected_fuel string?
---@field fuel_amount number

---@class TLLFuelCategoryData
---@field locomotives_fuel_categories table<string, string[]>
---@field fuel_categories_and_fuels table<string, string[]>