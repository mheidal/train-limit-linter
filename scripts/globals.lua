local blueprint_configuration = require("models/blueprint_configuration")
local schedule_table_configuration = require("models/schedule_table_configuration")
local keyword_list = require("models/keyword_list")
local fuel_configuration = require("models.fuel_configuration")

---@class TLLGlobal
---@field model TLLGlobalModel
---@field players table<number, TLLPlayerGlobal>

---@class TLLGlobalModel
---@field fuel_category_data TLLFuelCategoryData

---@class TLLPlayerGlobal
---@field model TLLPlayerModel
---@field view TLLPlayerView

---@class TLLPlayerModel
---@field blueprint_configuration TLLBlueprintConfiguration
---@field schedule_table_configuration TLLScheduleTableConfiguration
---@field fuel_configuration TLLFuelConfiguration
---@field excluded_keywords TLLKeywordList
---@field hidden_keywords TLLKeywordList
---@field last_gui_location GuiLocation?

---@class TLLPlayerView
---@field main_frame LuaGuiElement?
---@field report_frame LuaGuiElement?
---@field hide_content_frame LuaGuiElement?
---@field display_content_frame LuaGuiElement?
---@field exclude_content_frame LuaGuiElement?
---@field settings_content_frame LuaGuiElement?
---@field fuel_amount_flows table<string, LuaGuiElement> -- string is a fuel category (e.g. 'chemical')

local Exports = {}

---@return TLLPlayerView
function Exports.get_empty_player_view()
    return {
        fuel_amount_flows={}
    }
end

---@return TLLPlayerGlobal
function Exports.get_default_global()

    local fuel_config = fuel_configuration.TLLFuelConfiguration:new()

    local fuel_categories = global.model.fuel_category_data.fuel_categories_and_fuels

    for fuel_category, _ in pairs(fuel_categories) do
        fuel_config:add_fuel_category_config(fuel_category)
    end

    return {
        model = {
            blueprint_configuration = blueprint_configuration.TLLBlueprintConfiguration:new(),
            schedule_table_configuration = schedule_table_configuration.TLLScheduleTableConfiguration:new(),
            fuel_configuration = fuel_config,
            excluded_keywords = keyword_list.TLLKeywordList:new(),
            hidden_keywords = keyword_list.TLLKeywordList:new(),
            last_gui_location = nil, -- migration not actually necessary, since it starts as nil?
        },
        view = Exports.get_empty_player_view()
    }
end

function Exports.initialize_global(player)
    global.players[player.index] = Exports.get_default_global()
end

function Exports.migrate_global(player)
    global.players[player.index] = Exports.get_default_global()
end

return Exports