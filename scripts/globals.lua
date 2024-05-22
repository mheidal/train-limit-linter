local constants = require("constants")
local TLLBlueprintConfiguration = require("models.blueprint_configuration")
local TLLScheduleTableConfiguration = require("models.schedule_table_configuration")
local TLLKeywordList = require("models.keyword_list")
local TLLFuelConfiguration = require("models.fuel_configuration")
local fuel_category_data = require("models.fuel_category_data")
local TLLGeneralConfiguration = require("models.general_configuration")
local TLLTrainsToRemoveList = require("models.trains_to_remove_list")
local TLLOtherModsConfiguration = require("models.other_mods_configuration")
local TLLTrainList = require("models.train_list")
local TLLLTNTrainStopsList = require("models.ltn_stops_list")
local TLLGuiConfiguration = require("models.gui_configuration")

---@class TLLGlobal
---@field model TLLGlobalModel
---@field players {[number]: TLLPlayerGlobal}

---@class TLLGlobalModel
---@field fuel_category_data TLLFuelCategoryData
---@field train_list TLLTrainList
---@field ltn_stops_list TLLLTNTrainStopsList
---@field space_exploration_trains_teleporting_count number
---@field delay_rebuilding_interface boolean

---@class TLLPlayerGlobal
---@field model TLLPlayerModel
---@field view TLLPlayerView

---@class TLLPlayerModel
---@field blueprint_configuration TLLBlueprintConfiguration
---@field schedule_table_configuration TLLScheduleTableConfiguration
---@field fuel_configuration TLLFuelConfiguration
---@field excluded_keywords TLLKeywordList
---@field hidden_keywords TLLKeywordList
---@field collapsible_frame_configuration TLLCollapsibleFrameConfiguration
---@field inventory_scratch_pad LuaInventory
---@field general_configuration TLLGeneralConfiguration
---@field trains_to_remove_list TLLTrainsToRemoveList
---@field other_mods_configuration TLLOtherModsConfiguration
---@field gui_configuration TLLGuiConfiguration

---@class TLLPlayerView
---@field main_frame LuaGuiElement?
---@field report_frame LuaGuiElement?
---@field hide_content_frame LuaGuiElement?
---@field display_content_frame LuaGuiElement?
---@field exclude_content_frame LuaGuiElement?
---@field settings_content_frame LuaGuiElement?
---@field modal_main_frame LuaGuiElement?
---@field main_frame_dimmer LuaGuiElement?
---@field fuel_amount_flows table<string, LuaGuiElement> -- string is a fuel category (e.g. 'chemical')
---@field exclude_textfield LuaGuiElement?
---@field hide_textfield LuaGuiElement?

local Exports = {}

---@return TLLPlayerView
function Exports.get_empty_player_view()
    return {
        fuel_amount_flows={}
    }
end

---@param inventory_scratch_pad LuaInventory?
---@return TLLPlayerGlobal
function Exports.get_default_player_global(inventory_scratch_pad)

    local fuel_config = TLLFuelConfiguration.new()

    local fuel_categories = global.model.fuel_category_data.fuel_categories_and_fuels

    for fuel_category, _ in pairs(fuel_categories) do
        fuel_config:add_fuel_category_config(fuel_category)
    end

    return {
        model = {
            blueprint_configuration = TLLBlueprintConfiguration.new(),
            schedule_table_configuration = TLLScheduleTableConfiguration.new(),
            fuel_configuration = fuel_config,
            excluded_keywords = TLLKeywordList.new(),
            hidden_keywords = TLLKeywordList.new(),
            inventory_scratch_pad = inventory_scratch_pad or game.create_inventory(100),
            general_configuration = TLLGeneralConfiguration.new(),
            trains_to_remove_list = TLLTrainsToRemoveList.new(),
            other_mods_configuration = TLLOtherModsConfiguration.new(),
            gui_configuration = TLLGuiConfiguration.new()
        },
        view = Exports.get_empty_player_view()
    }
end

function Exports.build_global_model()
    global.model = {
        fuel_category_data = fuel_category_data.get_fuel_category_data(),
        ltn_stops_list = TLLLTNTrainStopsList.new(),
        train_list = TLLTrainList.new(),
        space_exploration_trains_teleporting_count = 0,
        delay_rebuilding_interface = false,
    }
    global.model.ltn_stops_list:initialize()
    global.model.train_list:initialize()
end

function Exports.initialize_global(player)
    global.players[player.index] = Exports.get_default_player_global()
end

function Exports.migrate_global(player)
    local old_global = global.players[player.index]
    local inventory_scratch_pad = old_global and old_global.model and old_global.model.inventory_scratch_pad
    local new_global = Exports.get_default_player_global(inventory_scratch_pad)

    for model_key, model_value in pairs(old_global.model) do
        if type(model_value) == "table" then
            for key, value in pairs(model_value) do
                if new_global.model[model_key] and new_global.model[model_key][key] ~= nil then
                    new_global.model[model_key][key] = value
                end
            end
        else
            if new_global.model[model_key] then
                new_global.model[model_key] = model_value
            end
        end
    end
    global.players[player.index] = new_global

    local toggleable_item_lists = {new_global.model.excluded_keywords.toggleable_items, new_global.model.hidden_keywords.toggleable_items}
    for _, toggleable_item_list in pairs(toggleable_item_lists) do
        for _, toggleable_item in pairs(toggleable_item_list) do
            if not toggleable_item.match_type then
                toggleable_item:set_match_type(constants.keyword_match_types.substring)
            end
        end
    end

end

---@param player_global TLLPlayerGlobal
---@param keyword_list_name string -- in constants.keyword_lists
---@return TLLKeywordList
function Exports.get_keyword_list_from_name(player_global, keyword_list_name)
    if keyword_list_name == constants.keyword_lists.exclude then return player_global.model.excluded_keywords
    elseif keyword_list_name == constants.keyword_lists.hide then return player_global.model.hidden_keywords
    else error("No such keyword list")
    end
end

---@param player_global TLLPlayerGlobal
---@param keyword_list_name string -- in constants.keyword_lists
---@return LuaGuiElement
function Exports.get_keyword_textfield_from_name(player_global, keyword_list_name)
    if keyword_list_name == constants.keyword_lists.exclude then return player_global.view.exclude_textfield
    elseif keyword_list_name == constants.keyword_lists.hide then return player_global.view.hide_textfield
    else error("No such keyword list")
    end
end

return Exports