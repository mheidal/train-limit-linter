---@class TLLFuelConfiguration
---@field add_fuel boolean
---@field fuel_category_configurations table<string, TLLFuelCategoryConfiguration>
---@field new fun(): TLLFuelCategoryConfiguration
---@field toggle_add_fuel fun(self: TLLFuelConfiguration)
---@field add_fuel_category_config fun(self: TLLFuelConfiguration, fuel_category: string)

---@class TLLFuelCategoryConfiguration
---@field selected_fuel string?
---@field fuel_amount number
---@field new fun(): TLLFuelCategoryConfiguration
---@field change_selected_fuel_and_check_overcap fun(self: TLLFuelCategoryConfiguration, string): boolean
---@field get_fuel_stack_size fun(self: TLLFuelCategoryConfiguration): number
---@field set_fuel_amount fun(self: TLLFuelCategoryConfiguration, number)

-- Fuel category configuration

local TLLFuelCategoryConfiguration = {}
local fuel_cat_mt = { __index = TLLFuelCategoryConfiguration }
script.register_metatable("TLLFuelCategoryConfiguration", fuel_cat_mt)

function TLLFuelCategoryConfiguration.new()
    local self = {
        selected_fuel = nil, -- nil or string
        fuel_amount = 0 -- 0 to 3 stacks of selected_fuel
    }
    setmetatable(self, fuel_cat_mt)
    return self
end

--- Changes which fuel type is selected in this fuel category. New trains in blueprints generated by the schedule table will request this fuel.
--- Returns true if this resulted in lowering the fuel_amount due to it exceeding there maximum amount of fuel that can possibly be loaded into a train.
--- Returns false otherwise. 
---@param selected_item string
---@return boolean 
function TLLFuelCategoryConfiguration:change_selected_fuel_and_check_overcap(selected_item)
    -- If the current config.selected_fuel == selected_item, deselect it
    if self.selected_fuel == selected_item then
        self.selected_fuel = nil
        self:set_fuel_amount(0)
        return false
    else
        self.selected_fuel = selected_item
        local new_max_value = self:get_fuel_stack_size() * global.model.fuel_category_data.maximum_fuel_slot_count
        if new_max_value < self.fuel_amount then
            self:set_fuel_amount(new_max_value)
            return true
        else
            return false
        end
    end
end

function TLLFuelCategoryConfiguration:get_fuel_stack_size()
    if self.selected_fuel then
        return game.item_prototypes[self.selected_fuel].stack_size
    else
        return 1
    end
end

---@param amount number
function TLLFuelCategoryConfiguration:set_fuel_amount(amount)
    self.fuel_amount = amount
end


-- Fuel configuration

local TLLFuelConfiguration = {}
local fuel_config_mt = { __index = TLLFuelConfiguration }
script.register_metatable("TLLFuelConfiguration", fuel_config_mt)

function TLLFuelConfiguration.new()
    local self = {
        add_fuel = true,
        fuel_category_configurations = {}
    }
    setmetatable(self, fuel_config_mt)
    return self
end

function TLLFuelConfiguration:toggle_add_fuel()
    self.add_fuel = not self.add_fuel
end

---@param fuel_category string
function TLLFuelConfiguration:add_fuel_category_config(fuel_category)
    self.fuel_category_configurations[fuel_category] = TLLFuelCategoryConfiguration:new()
end


return TLLFuelConfiguration
