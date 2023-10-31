local utils = require("utils")
local constants = require("constants")
local globals = require("scripts.globals")

-- Models

local train_data = require("models.train_data")

-- view
local slider_textfield = require("views.slider_textfield")
local icon_selector_textfield = require("views.icon_selector_textfield")

local main_interface = require("views.main_interface")

local display_tab_view = require("views.display_tab")
local keyword_tabs_view = require("views.keyword_tabs")
local settings_tab_view = require("views.settings_tab")

local modal = require("views.modal")

-- scripts

local schedule_report_table_scripts = require("scripts.schedule_report_table")

-- handlers

---@param player LuaPlayer
local function toggle_interface(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local main_frame = player_global.view.main_frame
    if main_frame == nil then
        player_global.model.main_interface_open = true
        main_interface.build_interface(player)
        player.opened = player_global.view.main_frame
    else
        local modal_main_frame = player_global.view.modal_main_frame
        if modal_main_frame then
            main_frame.ignored_by_interaction = true
        else
            player_global.model.main_interface_open = false
            player_global.model.last_gui_location = main_frame.location
            player_global.model.main_interface_selected_tab = nil
            main_frame.destroy()
            player_global.view = globals.get_empty_player_view()
        end
    end
end

---@param player LuaPlayer
function toggle_modal(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    local main_frame = player_global.view.main_frame
    local modal_main_frame = player_global.view.modal_main_frame

    if modal_main_frame == nil then
        if main_frame ~= nil then
            local dimmer = player.gui.screen.add{
                type="frame",
                style="tll_frame_semitransparent",
                tags={action=constants.actions.focus_modal}
            }
            dimmer.style.size = constants.style_data.main_frame_size
            dimmer.location = main_frame.location
            player_global.view.main_frame_dimmer = dimmer
        end
        modal.build_modal(player)
    else
        modal_main_frame.destroy()
        if player_global.view.main_frame_dimmer ~= nil then
            player_global.view.main_frame_dimmer.destroy()
            player_global.view.main_frame_dimmer = nil
        end
        player_global.view.modal_main_frame = nil
        if main_frame then
            player.opened = main_frame
            main_frame.ignored_by_interaction = false
        end
    end
end

-- event handlers

script.on_event("tll_toggle_interface", function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    toggle_interface(player)
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name ==  "tll_toggle_interface" then
        local player = game.get_player(event.player_index)
        if not player then return end
        toggle_interface(player)
    end
end)

script.on_event(defines.events.on_gui_click, function (event)
    local player = game.get_player(event.player_index)
    if not player then return end

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    if event.element.tags.action then
        local action = event.element.tags.action
         if action == constants.actions.select_fuel then
            local item_name = event.element.tags.item_name
            local fuel_category = event.element.tags.fuel_category
            if type(item_name) ~= "string" or type(fuel_category) ~= "string" then return end
            local fuel_config = player_global.model.fuel_configuration.fuel_category_configurations[fuel_category]
            if fuel_config:change_selected_fuel_and_check_overcap(item_name) then
                local fuel_category_slider_textfield_flow = player_global.view.fuel_amount_flows[fuel_category]
                local maximum_fuel_amount = fuel_config:get_fuel_stack_size() * global.model.fuel_category_data.maximum_fuel_slot_count
                slider_textfield.update_slider_value(fuel_category_slider_textfield_flow, maximum_fuel_amount)
            end

            settings_tab_view.build_settings_tab(player)

        elseif action == constants.actions.close_window then
            toggle_interface(player)

        elseif action == constants.actions.exclude_textfield_apply then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.excluded_keywords:set_enabled(text, true)
                main_interface.build_interface(player)
            end

        elseif action == constants.actions.delete_excluded_keyword then
            local excluded_keyword = event.element.tags.keyword
            if type(excluded_keyword) ~= "string" then return end
            player_global.model.excluded_keywords:remove_item(excluded_keyword)
            main_interface.build_interface(player)

        elseif action == constants.actions.delete_all_excluded_keywords then

            player_global.model.excluded_keywords:remove_all()
            main_interface.build_interface(player)

        elseif action == constants.actions.hide_textfield_apply then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.hidden_keywords:set_enabled(text, true)
                main_interface.build_interface(player)
            end

        elseif action == constants.actions.delete_hidden_keyword then
            local hidden_keyword = event.element.tags.keyword
            if type(hidden_keyword) ~= "string" then return end
            player_global.model.hidden_keywords:remove_item(hidden_keyword)
            main_interface.build_interface(player)

        elseif action == constants.actions.delete_all_hidden_keywords then
            player_global.model.hidden_keywords:remove_all()
            main_interface.build_interface(player)

        elseif action == constants.actions.train_schedule_create_blueprint then
            local template_train
            local template_train_ids = event.element.tags.template_train_ids
            if type(template_train_ids) ~= "table" then return end
            for _, id in pairs(template_train_ids) do
                local template_option = game.get_train_by_id(id)
                if template_option then
                    template_train = template_option
                    break
                end
            end
            if template_train == nil then
                player.create_local_flying_text{text={"tll.no_valid_template_trains"}, create_at_cursor=true}
                return
            end
            local surface_name = event.element.tags.surface
            if type(surface_name) ~= "string" then return end
            schedule_report_table_scripts.create_blueprint_from_train(player, template_train, surface_name)

        elseif action == constants.actions.train_schedule_ping_manual_trains then
            local surface = event.element.tags.surface
            local manual_train_ids = event.element.tags.manual_train_ids
            if type(manual_train_ids) ~= "table" then return end
            local schedule_name = event.element.tags.schedule_name

            local chat_string = {"tll.manual_train_list", #manual_train_ids, schedule_name}
            for _, id in pairs(manual_train_ids) do
                local train = game.get_train_by_id(id)
                if train then
                    local train_pos = train.carriages[1].position
                    local x = string.format("%.1f", train_pos.x)
                    local y = string.format("%.1f", train_pos.y)
                    chat_string = {"", chat_string, "\n[gps=" .. x .. "," .. y}
                    if surface ~= constants.default_surface_name then
                        chat_string = {"", chat_string, "," .. surface}
                    end
                    chat_string = {"", chat_string, "]"}
                end
            end
            player.print(chat_string)

        elseif action == constants.actions.set_blueprint_orientation then
            local orientation = event.element.tags.orientation
            if type(orientation) ~= "number" then return end
            player_global.model.blueprint_configuration:set_new_blueprint_orientation(orientation)
            main_interface.build_interface(player)

        elseif action == constants.actions.open_modal then
            local modal_function = event.element.tags.modal_function
            local args = event.element.tags.args
            if not modal_function then return end
            if type(modal_function) ~= "string" or not constants.modal_functions[modal_function] then return end
            if type(args) ~= "table" and args ~= nil then return end

            player_global.model.modal_function_configuration:set_modal_content_function(modal_function)
            ---@diagnostic disable-next-line vscode is angry about the type of "args"
            player_global.model.modal_function_configuration:set_modal_content_args(args)
            toggle_modal(player)

        elseif action == constants.actions.close_modal then
            player_global.model.modal_function_configuration:clear_modal_content_function()
            player_global.model.modal_function_configuration:clear_modal_content_args()
            toggle_modal(player)

        elseif action == constants.actions.import_keywords_button then
            local textfield_flow = event.element.parent
            if not textfield_flow then return end
            local text = textfield_flow["textfield"].text
            if text == "" then return end -- don't allow user to input the empty string
            textfield_flow["textfield"].text = ""

            if not event.element.tags.keywords then return end
            local keywords_tag = event.element.tags.keywords
            if type(keywords_tag) ~= "string" then return end
            local keyword_list = globals.get_keyword_list_from_name(player_global, keywords_tag)
            keyword_list:add_from_serialized(text)

            main_interface.build_interface(player)
            toggle_modal(player)

        elseif action == constants.actions.focus_modal then
            local modal_main_frame = player_global.view.modal_main_frame
            if modal_main_frame then
                player.opened = modal_main_frame
                modal_main_frame.bring_to_front()
            end
            
        elseif action == constants.actions.train_stop_name_selector_select_name then
            if not event.element.tags.train_stop_name then return end
            if not event.element.tags.keywords then return end
            local keywords_tag = event.element.tags.keywords
            if type(keywords_tag) ~= "string" then return end
            local keyword_textfield = globals.get_keyword_textfield_from_name(player_global, keywords_tag)
            keyword_textfield.text = keyword_textfield.text .. event.element.tags.train_stop_name
            keyword_textfield.focus()
            toggle_modal(player)

        elseif action == constants.actions.main_interface_switch_tab then
            local tab_index = event.element.tags.tab_index
            if not tab_index then return end
            if type(tab_index) ~= "number" then return end
            player_global.model.main_interface_selected_tab = tab_index
            main_interface.build_interface(player)
        end
    end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
    local player = game.get_player(event.player_index)
    if not player then return end -- 

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    if event.element.tags.action then
        local action = event.element.tags.action
        if action == constants.actions.toggle_excluded_keyword then
            local keyword = event.element.tags.keyword
            if type(keyword) ~= "string" then return end
            player_global.model.excluded_keywords:toggle_enabled(keyword)

        elseif action == constants.actions.toggle_hidden_keyword then
            local keyword = event.element.tags.keyword
            if type(keyword) ~= "string" then return end
            player_global.model.hidden_keywords:toggle_enabled(keyword)

        elseif action == constants.actions.toggle_show_all_surfaces then
            player_global.model.schedule_table_configuration:toggle_show_all_surfaces()
            main_interface.build_interface(player)

        elseif action == constants.actions.toggle_show_satisfied then
            player_global.model.schedule_table_configuration:toggle_show_satisfied()
            main_interface.build_interface(player)

        elseif action == constants.actions.toggle_show_invalid then
            player_global.model.schedule_table_configuration:toggle_show_invalid()
            main_interface.build_interface(player)

        elseif action == constants.actions.toggle_show_manual then
            player_global.model.schedule_table_configuration:toggle_show_manual()
            main_interface.build_interface(player)

        elseif action == constants.actions.toggle_blueprint_snap then
            player_global.model.blueprint_configuration:toggle_blueprint_snap()
            main_interface.build_interface(player)

        elseif action == constants.actions.toggle_place_trains_with_fuel then
            player_global.model.fuel_configuration:toggle_add_fuel()
            main_interface.build_interface(player)
        end
    end
end)

script.on_event(defines.events.on_gui_value_changed, function (event)
    local player = game.get_player(event.player_index)
    if not player then return end

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    -- handler for slider_textfield element: when the slider updates, update the textfield
    if event.element.tags.slider_textfield then
        local slider_textfield_flow = event.element.parent
        if not slider_textfield_flow then return end
        slider_textfield.update_textfield_value(slider_textfield_flow)
    end

    -- handler for actions: if the element has a tag with key 'action' then we perform whatever operation is associated with that action.
    if event.element.tags.action then
        local action = event.element.tags.action
        if action == constants.actions.update_fuel_amount then
            local new_fuel_amount = event.element.slider_value
            local fuel_category = event.element.tags.fuel_category
            local fuel_config = player_global.model.fuel_configuration.fuel_category_configurations[fuel_category]
            fuel_config:set_fuel_amount(new_fuel_amount)
        elseif action == constants.actions.set_blueprint_snap_width then
            local new_snap_width = event.element.slider_value
            player_global.model.blueprint_configuration:set_snap_width(new_snap_width)
        end
    end
end)

script.on_event(defines.events.on_gui_text_changed, function (event)
    local player = game.get_player(event.player_index)
    if not player then return end -- 

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    if event.element.tags.action then
        local action = event.element.tags.action
        if action == constants.actions.update_fuel_amount then
            -- this caps the textfield's value
            local new_fuel_amount = tonumber(event.element.text)
            if type(new_fuel_amount) == "number" then
                local fuel_config = player_global.model.fuel_configuration.fuel_category_configurations[event.element.tags.fuel_category]
                fuel_config:set_fuel_amount(new_fuel_amount)
            end

        elseif action == constants.actions.set_blueprint_snap_width then
            local new_snap_width = tonumber(event.element.text)
            if not new_snap_width then return end
            player_global.model.blueprint_configuration:set_snap_width(new_snap_width)
        end
    end

    -- handler for slider_textfield element: when the slider updates, update the textfield
    if event.element.tags.slider_textfield then
        local slider_textfield_flow = event.element.parent
        if not slider_textfield_flow then return end
        slider_textfield.update_slider_value(slider_textfield_flow)
    end
end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end -- 

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    if event.element.tags.action then
        local action = event.element.tags.action
        if action == constants.actions.icon_selector_icon_selected then
            icon_selector_textfield.handle_icon_selection(event.element)
        end
    end
end)

script.on_event(defines.events.on_gui_switch_state_changed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end -- 

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    if event.element.tags.action then
        local action = event.element.tags.action
        if action == constants.actions.toggle_blueprint_snap_direction then
            player_global.model.blueprint_configuration:toggle_snap_direction()
        end
    end
end)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.element then
        local player = game.get_player(event.player_index)
        if not player then return end
        ---@type TLLPlayerGlobal
        local player_global = global.players[player.index]
        if player_global.view.modal_main_frame then
            player.opened = player_global.view.modal_main_frame
        end
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    if event.element then
        local player = game.get_player(event.player_index)
        if not player then return end
        local name = event.element.name
        if name == "tll_main_frame" then
            toggle_interface(player)
        elseif name == "tll_modal_main_frame" then
            toggle_modal(player)
        end
    end
end)

script.on_event(defines.events.on_gui_confirmed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end -- 

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    if event.element.tags.action then
        local action = event.element.tags.action
        if action == constants.actions.exclude_textfield_enter_text then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.excluded_keywords:set_enabled(text, true)
                main_interface.build_interface(player)
            end
        elseif action == constants.actions.hide_textfield_enter_text then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.hidden_keywords:set_enabled(text, true)
                main_interface.build_interface(player)
            end
        elseif action == constants.actions.import_keywords_textfield then
            local text = event.element.text
            if text == "" then return end -- don't allow user to input the empty string
            event.element.text = ""
            if not event.element.tags.keywords then return end
            local keywords_tag = event.element.tags.keywords
            if type(keywords_tag) ~= "string" then return end
            local keyword_list = globals.get_keyword_list_from_name(player_global, keywords_tag)
            keyword_list:add_from_serialized(text)

            main_interface.build_interface(player)

            toggle_modal(player)
        end
    end
end)

---@param entity LuaEntity
local function register_rolling_stock(entity)
    local prototype_type = entity.prototype.type
    if (prototype_type == "locomotive"
    or prototype_type == "cargo-wagon"
    or prototype_type == "fluid-wagon"
    or prototype_type == "artillery-wagon")
    then
        script.register_on_entity_destroyed(entity)
    end
end

script.on_event(defines.events.on_built_entity, function(event)
    register_rolling_stock(event.created_entity)
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
    register_rolling_stock(event.created_entity)
end)

script.on_event(defines.events.script_raised_built, function(event)
    register_rolling_stock(event.entity)
end)

script.on_event(defines.events.script_raised_revive, function(event)
    register_rolling_stock(event.entity)
end)

script.on_event(defines.events.on_trigger_created_entity, function(event)
    register_rolling_stock(event.entity)
end)

script.on_event(defines.events.on_entity_cloned, function(event)
    register_rolling_stock(event.destination)
end)

script.on_event(defines.events.on_entity_destroyed, function(event)
    if global.model.tracked_rolling_stock[event.unit_number] then
        local train_id = global.model.tracked_rolling_stock[event.unit_number]
        if not game.get_train_by_id(train_id) then
            global.model.tracked_rolling_stock[event.unit_number] = nil
            global.model.train_data[train_id] = nil
            for _, player in pairs(game.players) do
                main_interface.build_interface(player)
            end
        end
    end
end)

script.on_event(defines.events.on_train_created, function (event)
    local global_train_data = global.model.train_data

    if event.old_train_id_1 then
        global_train_data[event.old_train_id_1] = nil
    end

    if event.old_train_id_2 then
        global_train_data[event.old_train_id_2] = nil
    end

    global_train_data[event.train.id] = train_data.build_single_train_data(event.train)

    for _, carriage in pairs(event.train.carriages) do
        if carriage.unit_number then
            global.model.tracked_rolling_stock[carriage.unit_number] = event.train.id
        end
    end

    for _, player in pairs(game.players) do
        main_interface.build_interface(player)
    end
end)

script.on_event(defines.events.on_train_changed_state, function (event)
    local this_train_data = global.model.train_data[event.train.id]
    if not this_train_data.manual_mode == event.train.manual_mode then
        this_train_data.manual_mode = event.train.manual_mode
        for _, player in pairs(game.players) do
            main_interface.build_interface(player)
        end
    end
end)

script.on_event(defines.events.on_train_schedule_changed, function (event)
    local schedule = {}
    if event.train.schedule then
        global.model.train_data[event.train.id].schedule_key = utils.train_schedule_to_key(event.train.schedule)
        for _, record in pairs(event.train.schedule.records) do
            table.insert(schedule, record.station)
        end
    else
        global.model.train_data[event.train.id].schedule_key = ""
    end
    global.model.train_data[event.train.id].schedule = schedule

    for _, player in pairs(game.players) do
        main_interface.build_interface(player)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    globals.initialize_global(player)
end)

script.on_event(defines.events.on_player_removed, function(event)
    global.players[event.player_index] = nil
end)

script.on_init(function ()

    globals.build_global_model()

    local freeplay = remote.interfaces["freeplay"]
    if freeplay then -- TODO: remove this when done with testing
        if freeplay["set_skip_intro"] then remote.call("freeplay", "set_skip_intro", true) end
        if freeplay["set_disable_crashsite"] then remote.call("freeplay", "set_disable_crashsite", true) end
    end
    global.players = {}
    for _, player in pairs(game.players) do
        globals.initialize_global(player)
    end
end)

script.on_configuration_changed(function (config_changed_data)
    globals.build_global_model()

    if config_changed_data.mod_changes["train-limit-linter"] then
        for _, player in pairs(game.players) do
            globals.migrate_global(player)

            ---@type TLLPlayerGlobal
            local player_global = global.players[player.index]
            if player_global.view.main_frame ~= nil then
                toggle_interface(player)
            else
                player.opened = nil
            end
        end
    end
end)
