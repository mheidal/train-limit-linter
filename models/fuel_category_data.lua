
---@class TLLFuelCategoryData
---@field locomotives_fuel_categories table<string, string[]>
---@field fuel_categories_and_fuels table<string, string[]>
---@field maximum_fuel_slot_count number

local Exports = {}

local function get_fuel_categories_consumed_by_locomotives()
    local fuel_categories = {} -- set
    for _, proto in pairs(game.entity_prototypes) do
        if proto.type == "locomotive" then
            if proto.burner_prototype then
                for fuel_category, _ in pairs(proto.burner_prototype.fuel_categories) do
                    fuel_categories[fuel_category] = true
                end
            end
        end
    end
    return fuel_categories
end

local function get_fuels_in_fuel_category(fuel_category)
    local fuels = {}
    for _, proto in pairs(game.item_prototypes) do
        if proto.fuel_category and proto.fuel_category == fuel_category then
            table.insert(fuels, proto.name)
        end
    end
    return fuels
end

function get_fuel_categories_and_fuels()
    local fuel_categories = get_fuel_categories_consumed_by_locomotives()
    for fuel_category, _ in pairs(fuel_categories) do
        fuel_categories[fuel_category] = get_fuels_in_fuel_category(fuel_category)
    end
    return fuel_categories
end

function get_locomotives_and_fuel_categories()
    local locomotives_fuel_categories = {}
    for _, proto in pairs(game.entity_prototypes) do
        if proto.type == "locomotive" then
            if proto.burner_prototype then
                local consumed_fuel_categories = {}
                for fuel_category, _ in pairs(proto.burner_prototype.fuel_categories) do
                    table.insert(consumed_fuel_categories, fuel_category)
                end
                locomotives_fuel_categories[proto.name] = consumed_fuel_categories
            end
        end
    end
    return locomotives_fuel_categories
end

local function get_maximum_fuel_slot_count()
    local max = 0
    for _, proto in pairs(game.entity_prototypes) do
        if proto.type == "locomotive" then
            if proto.burner_prototype then
                local fuel_slot_count = proto.burner_prototype.fuel_inventory_size
                max = max > fuel_slot_count and max or fuel_slot_count
            end
        end
    end
    return max
end

---@return TLLFuelCategoryData
function Exports.get_fuel_category_data()
    return {
        locomotives_fuel_categories = get_locomotives_and_fuel_categories(),
        fuel_categories_and_fuels = get_fuel_categories_and_fuels(),
        maximum_fuel_slot_count = get_maximum_fuel_slot_count(),
    }
end

return Exports