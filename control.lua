local constants = require("constants")
local globals = require("scripts.globals")

-- view
local collapsible_frame = require("views.collapsible_frame")
local slider_textfield = require("views.slider_textfield")
local icon_selector_textfield = require("views.icon_selector_textfield")

local main_interface = require("views.main_interface")

local settings_tab_view = require("views.settings_tab")

local modal = require("views.modal")

-- scripts

local schedule_report_table_scripts = require("scripts.schedule_report_table")

local blueprint_creation_scripts = require("scripts.blueprint_creation")

local train_removal_scripts = require("scripts.train_removal")

-- handlers

---@param player LuaPlayer
local function rebuild_interfaces(player)
    main_interface.build_interface(player)
    modal.build_modal(player)
end

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
        player_global.model.modal_open = true

        modal.pre_build_cleanup(player)
        modal.build_modal(player)
    else
        player_global.model.modal_open = false
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

        elseif action == constants.actions.keyword_textfield_apply then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            local keywords_name = event.element.tags.keywords
            if not keywords_name or type(keywords_name) ~= "string" then return end
            if text ~= "" then -- don't allow user to input the empty string
                local keyword_list = globals.get_keyword_list_from_name(player_global, keywords_name)
                keyword_list:set_enabled(text, true)
                rebuild_interfaces(player)
            end

        elseif action == constants.actions.delete_keyword then
            local keyword = event.element.tags.keyword
            if type(keyword) ~= "string" then return end
            local keywords_name = event.element.tags.keywords
            if not keywords_name or type(keywords_name) ~= "string" then return end
            local keyword_list = globals.get_keyword_list_from_name(player_global, keywords_name)
            keyword_list:remove_item(keyword)
            rebuild_interfaces(player)

        elseif action == constants.actions.delete_all_keywords then
            local keywords_name = event.element.tags.keywords
            if not keywords_name or type(keywords_name) ~= "string" then return end
            local keyword_list = globals.get_keyword_list_from_name(player_global, keywords_name)
            keyword_list:remove_all()
            rebuild_interfaces(player)

        elseif action == constants.actions.train_schedule_create_blueprint then
            blueprint_creation_scripts.schedule_report_table_create_blueprint(event, player, player_global)

        elseif action == constants.actions.train_schedule_create_blueprint_and_ping_trains then
            blueprint_creation_scripts.schedule_report_table_create_blueprint(event, player, player_global)
            local parked_trains = event.element.tags.parked_train_positions
            if not parked_trains or type(parked_trains) ~= "table" then return end
            for _, parked_train in pairs(parked_trains) do
                player.print{"tll.train_parked_at_stop", parked_train.train_stop, parked_train.position.x, parked_train.position.y, event.element.tags.surface}
            end

        elseif action == constants.actions.set_blueprint_orientation then
            local orientation = event.element.tags.orientation
            if type(orientation) ~= "number" then return end
            player_global.model.blueprint_configuration:set_new_blueprint_orientation(orientation)
            if orientation == constants.orientations.d or orientation == constants.orientations.u then
                player_global.model.blueprint_configuration:set_snap_direction(constants.snap_directions.horizontal)
            elseif orientation == constants.orientations.l or orientation == constants.orientations.r then
                player_global.model.blueprint_configuration:set_snap_direction(constants.snap_directions.vertical)
            end
            rebuild_interfaces(player)

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

            rebuild_interfaces(player)
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
            rebuild_interfaces(player)

        elseif action == constants.actions.toggle_display_settings_visible then
            player_global.model.collapsible_frame_configuration:toggle_display_settings_visible()
            collapsible_frame.toggle_collapsible_frame_visible(event.element)

        elseif action == constants.actions.toggle_blueprint_settings_visible then
            player_global.model.collapsible_frame_configuration:toggle_blueprint_settings_visible()
            collapsible_frame.toggle_collapsible_frame_visible(event.element)

        elseif action == constants.actions.toggle_fuel_settings_visible then
            player_global.model.collapsible_frame_configuration:toggle_fuel_settings_visible()
            collapsible_frame.toggle_collapsible_frame_visible(event.element)

        elseif action == constants.actions.toggle_general_settings_visible then
            player_global.model.collapsible_frame_configuration:toggle_general_settings_visible()
            collapsible_frame.toggle_collapsible_frame_visible(event.element)

        elseif action == constants.actions.toggle_other_mods_settings_visible then
            player_global.model.collapsible_frame_configuration:toggle_other_mods_settings_visible()
            collapsible_frame.toggle_collapsible_frame_visible(event.element)

        elseif action == constants.actions.remove_trains then
            local remove_train_option = player_global.model.general_configuration.remove_train_option

            for train_id, _ in pairs(player_global.model.trains_to_remove_list:get_trains_to_remove()) do
                if remove_train_option == constants.remove_train_option_enums.mark then
                    train_removal_scripts.mark_train_for_deconstruction(train_id, player)

                elseif remove_train_option== constants.remove_train_option_enums.delete then
                    train_removal_scripts.delete_train(train_id, player)
                end
            end
            player_global.model.trains_to_remove_list:remove_all()
            toggle_modal(player)
            rebuild_interfaces(player)

        elseif action == constants.actions.toggle_train_to_remove_button then
            local train_id = event.element.tags.train_id
            if not train_id then return end
            if type(train_id) ~= "number" then return end
            local checkbox = event.element.parent.parent.parent[constants.gui_element_names.train_removal_modal.checkbox]
            if player_global.model.trains_to_remove_list:get_trains_to_remove()[train_id] then
                player_global.model.trains_to_remove_list:remove(train_id)
                checkbox.state = false
            else
                player_global.model.trains_to_remove_list:add(train_id)
                checkbox.state = true
            end

        elseif action == constants.actions.open_train then

            local train_id = event.element.tags.train_id
            if not train_id or type(train_id) ~= "number" then return end

            local train = game.get_train_by_id(train_id)
            if not train or not train.valid or not train.front_stock then return end

            if player_global.model.modal_open then toggle_modal(player) end
            if player_global.model.main_interface_open then toggle_interface(player) end
            player.opened = train.front_stock
        end
    end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
    local player = game.get_player(event.player_index)
    if not player then return end

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    if event.element.tags.action then
        local action = event.element.tags.action
        if event.element.type == "checkbox" then
            if false then

            elseif action == constants.actions.toggle_keyword then
                local keyword = event.element.tags.keyword
                if type(keyword) ~= "string" then return end
                local keywords_name = event.element.tags.keywords
                if not keywords_name or type(keywords_name) ~= "string" then return end
                local keyword_list = globals.get_keyword_list_from_name(player_global, keywords_name)
                keyword_list:toggle_enabled(keyword)

            elseif action == constants.actions.toggle_show_all_surfaces then
                player_global.model.schedule_table_configuration:toggle_show_all_surfaces()
                rebuild_interfaces(player)

            elseif action == constants.actions.toggle_show_satisfied then
                player_global.model.schedule_table_configuration:toggle_show_satisfied()
                rebuild_interfaces(player)

            elseif action == constants.actions.toggle_show_not_set then
                player_global.model.schedule_table_configuration:toggle_show_not_set()
                rebuild_interfaces(player)

            elseif action == constants.actions.toggle_show_dynamic then
                player_global.model.schedule_table_configuration:toggle_show_dynamic()
                rebuild_interfaces(player)

            elseif action == constants.actions.toggle_show_single_station_schedules then
                player_global.model.schedule_table_configuration:toggle_show_single_station_schedules()
                rebuild_interfaces(player)

            elseif action == constants.actions.toggle_show_train_limits_separately then
                player_global.model.schedule_table_configuration:toggle_show_train_limits_separately()
                rebuild_interfaces(player)

            elseif action == constants.actions.toggle_blueprint_snap then
                player_global.model.blueprint_configuration:toggle_blueprint_snap()
                rebuild_interfaces(player)

            elseif action == constants.actions.toggle_place_trains_with_fuel then
                player_global.model.fuel_configuration:toggle_add_fuel()
                rebuild_interfaces(player)

            elseif action == constants.actions.toggle_include_train_stops then
                player_global.model.blueprint_configuration:toggle_include_train_stops()
                rebuild_interfaces(player)

            elseif action == constants.actions.toggle_limit_train_stops then
                player_global.model.blueprint_configuration:toggle_limit_train_stops()
                rebuild_interfaces(player)

            elseif action == constants.actions.toggle_opinionation then
                player_global.model.schedule_table_configuration:toggle_opinionate()
                rebuild_interfaces(player)

            elseif action == constants.actions.toggle_train_to_remove_checkbox then
                local train_id = event.element.tags.train_id
                if not train_id then return end
                if type(train_id) ~= "number" then return end
                if event.element.state then
                    player_global.model.trains_to_remove_list:add(train_id)
                else
                    player_global.model.trains_to_remove_list:remove(train_id)
                end

            elseif action == constants.actions.toggle_TrainGroups_copy_train_group then
                player_global.model.other_mods_configuration.TrainGroups_configuration:toggle_copy_train_group()
                rebuild_interfaces(player)
            end

        elseif event.element.type == "radiobutton" then
            if action == constants.actions.change_remove_train_option then
                local new_option = event.element.tags.new_option
                if not new_option or type(new_option) ~= "string" then return end
                player_global.model.general_configuration:change_remove_train_option(new_option)
                rebuild_interfaces(player)
            end
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

        elseif action == constants.actions.set_default_train_limit then
            local new_default_limit = event.element.slider_value
            player_global.model.blueprint_configuration:set_default_train_limit(new_default_limit)
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

        elseif action == constants.actions.set_default_train_limit then
            local new_default_limit = tonumber(event.element.text)
            if not new_default_limit then return end
            player_global.model.blueprint_configuration:set_default_train_limit(new_default_limit)
        end
    end

    -- handler for slider_textfield element: when the textfield updates, update the slider
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
    if not player then return end

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    if event.element.tags.action then
        local action = event.element.tags.action
        if action == constants.actions.toggle_blueprint_snap_direction then
            player_global.model.blueprint_configuration:toggle_snap_direction()

        elseif action == constants.actions.set_keyword_match_type then
            local keyword = event.element.tags.keyword
            if not keyword or type(keyword) ~= "string" then return end
            local keywords_name = event.element.tags.keywords
            if not keywords_name or type(keywords_name) ~= "string" then return end
            local keyword_list = globals.get_keyword_list_from_name(player_global, keywords_name)

            if event.element.switch_state == "left" then
                keyword_list:set_match_type(keyword, constants.keyword_match_types.exact)
            elseif event.element.switch_state == "right" then
                keyword_list:set_match_type(keyword, constants.keyword_match_types.substring)
            end
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

        if action == constants.actions.keyword_textfield_enter_text then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                local keywords_name = event.element.tags.keywords
                if not keywords_name or type(keywords_name) ~= "string" then return end
                local keyword_list = globals.get_keyword_list_from_name(player_global, keywords_name)
                keyword_list:set_enabled(text, true)
                rebuild_interfaces(player)
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

            rebuild_interfaces(player)

            toggle_modal(player)
        end
    end
end)

script.on_event(defines.events.on_gui_location_changed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    if player_global.model.main_interface_open and player_global.view.main_frame == event.element then
        player_global.model.last_gui_location = event.element.location
    elseif player_global.model.modal_open and player_global.view.modal_main_frame == event.element then
        player_global.model.last_modal_location = event.element.location
    end

end)

script.on_event(defines.events.on_train_created, function (event)

    ---@type TLLTrainList
    local train_list = global.model.train_list

    if event.old_train_id_1 then
        train_list:remove_by_id(event.old_train_id_1)
    end

    if event.old_train_id_2 then
        train_list:remove_by_id(event.old_train_id_2)
    end

    train_list:add(event.train)

    for _, player in pairs(game.players) do
        rebuild_interfaces(player)
    end
end)

script.on_nth_tick(120, function (_)
    local any_trains_removed = global.model.train_list:validate()
    if any_trains_removed then
        for _, player in pairs(game.players) do
            rebuild_interfaces(player)
        end
    end
end)

script.on_nth_tick(3600, function(_)
    ---@type TLLLTNTrainStopsList
    local ltn_stops_list = global.model.ltn_stops_list
    ltn_stops_list:validate()
end)

script.on_event(defines.events.on_entity_renamed, function (event)
    local entity = event.entity
    if entity.name == "logistic-train-stop" or entity.name == "ltn-port" then
        ---@type TLLLTNTrainStopsList
        local ltn_stops_list = global.model.ltn_stops_list
        ltn_stops_list:remove_by_backer_name_and_unit_number(event.old_name, entity.unit_number)
        ltn_stops_list:add(entity)
    end
end)

script.on_event(defines.events.on_train_schedule_changed, function (event)
    if not global.model.train_list.trains[event.train.id].belongs_to_LTN then
        for _, player in pairs(game.players) do
            rebuild_interfaces(player)
        end
    end
end)

---@todo handlers for creation and destruction of LTN stops

---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.on_entity_cloned | EventData.script_raised_built | EventData.script_raised_revive
local function handle_build(event)
    local entity = event.entity or event.created_entity
    if not entity then return end

    ---@type TLLLTNTrainStopsList
    local ltn_stops_list = global.model.ltn_stops_list
    ltn_stops_list:add(entity)
end

for _, event in pairs({ "on_built_entity", "on_robot_built_entity", "on_entity_cloned", "script_raised_built", "script_raised_revive" }) do
    script.on_event(defines.events[event], handle_build, { {filter="name", name="logistic-train-stop"}, {filter="name", name="ltn-port"} }) ---@diagnostic disable-line
end

script.on_event(defines.events.on_entity_destroyed, function (event)
    ---@type TLLLTNTrainStopsList
    local ltn_stops_list = global.model.ltn_stops_list
    ltn_stops_list:remove_by_unit_number(event.unit_number)
end)

script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    globals.initialize_global(player)
end)

script.on_event(defines.events.on_player_removed, function(event)
    global.players[event.player_index].model.inventory_scratch_pad.destroy()
    global.players[event.player_index] = nil
end)

script.on_init(function ()

    globals.build_global_model()

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