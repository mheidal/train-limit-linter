local constants = require("constants")
local TLLBlueprintConfiguration = require("models.blueprint_configuration")
local TLLScheduleTableConfiguration = require("models.schedule_table_configuration")
local TLLKeywordList = require("models.keyword_list")
local TLLFuelConfiguration = require("models.fuel_configuration")
local TLLModalFunctionConfiguration = require("models.modal_function_configuration")
local fuel_category_data = require("models.fuel_category_data")
local TLLCollapsibleFrameConfiguration = require("models.collapsible_frame_configuration")
local TLLGeneralConfiguration = require("models.general_configuration")

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
---@field modal_function_configuration TLLModalFunctionConfiguration
---@field main_interface_selected_tab number?
---@field main_interface_open boolean
---@field collapsible_frame_configuration TLLCollapsibleFrameConfiguration
---@field inventory_scratch_pad LuaInventory
---@field general_configuration TLLGeneralConfiguration

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
            last_gui_location = nil,
            modal_function_configuration = TLLModalFunctionConfiguration.new(),
            main_interface_open=false,
            collapsible_frame_configuration = TLLCollapsibleFrameConfiguration.new(),
            inventory_scratch_pad = inventory_scratch_pad or game.create_inventory(100),
            general_configuration = TLLGeneralConfiguration.new(),
        },
        view = Exports.get_empty_player_view()
    }
end

function Exports.build_global_model()
    global.model = {
        fuel_category_data = fuel_category_data.get_fuel_category_data(),
    }
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