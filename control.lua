local constants = require("constants")
local globals = require("scripts.globals")

-- Models
local fuel_category_data = require("models.fuel_category_data")

-- view
local slider_textfield = require("views/slider_textfield")
local icon_selector_textfield = require("views/icon_selector_textfield")

local display_tab_view = require("views/display_tab")
local keyword_tabs_view = require("views/keyword_tabs")
local settings_tab_view = require("views/settings_tab")

local modal = require("views/modal")

-- scripts

local schedule_report_table_scripts = require("scripts/schedule_report_table")


-- interface 

---@param player LuaPlayer
local function build_interface(player)
    ---@TLLPlayerGlobal
    local player_global = global.players[player.index]

    local screen_element = player.gui.screen

    local main_frame = screen_element.add{type="frame", name="tll_main_frame", direction="vertical"}
    main_frame.style.size = constants.style_data.main_frame_size

    if not player_global.model.last_gui_location then
        main_frame.auto_center = true
    else
        main_frame.location = player_global.model.last_gui_location
    end

    player.opened = main_frame
    player_global.view.main_frame = main_frame

    -- titlebar
    local titlebar_flow = main_frame.add{
        type="flow",
        direction="horizontal",
        name="tll_titlebar_flow",
        style="flib_titlebar_flow"
    }
    titlebar_flow.drag_target = main_frame
    titlebar_flow.add{type="label", style="frame_title", caption={"tll.main_frame_header"}}
    titlebar_flow.add{type="empty-widget", style="flib_titlebar_drag_handle", ignored_by_interaction=true}
    titlebar_flow.add{type="sprite-button", tags={action=constants.actions.close_window}, style="frame_action_button", sprite = "utility/close_white", tooltip={"tll.close"}}

    -- tabs
    local tab_pane_frame = main_frame.add{type="frame", style="inside_deep_frame_for_tabs"}
    local tabbed_pane = tab_pane_frame.add{type="tabbed-pane", style="tabbed_pane_with_no_side_padding"}

    -- display tab
    local display_tab = tabbed_pane.add{type="tab", caption={"tll.display_tab"}}
    local display_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="tll_tab_content_frame"}
    tabbed_pane.add_tab(display_tab, display_content_frame)

    player_global.view.display_content_frame = display_content_frame

    display_tab_view.build_display_tab(player)

    -- exclude tab
    local exclude_tab = tabbed_pane.add{type="tab", caption={"tll.exclude_tab"}}
    local exclude_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="tll_tab_content_frame"}
    tabbed_pane.add_tab(exclude_tab, exclude_content_frame)
    player_global.view.exclude_content_frame = exclude_content_frame

    keyword_tabs_view.build_exclude_tab(player)

    -- hide tab
    local hide_tab = tabbed_pane.add{type="tab", caption={"tll.hide_tab"}}
    local hide_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="tll_tab_content_frame"}
    tabbed_pane.add_tab(hide_tab, hide_content_frame)
    player_global.view.hide_content_frame = hide_content_frame

    keyword_tabs_view.build_hide_tab(player)

    -- settings tab
    local settings_tab = tabbed_pane.add{type="tab", caption={"tll.settings_tab"}}
    local settings_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="tll_tab_content_frame"}
    tabbed_pane.add_tab(settings_tab, settings_content_frame)

    player_global.view.settings_content_frame = settings_content_frame

    settings_tab_view.build_settings_tab(player)

end

---@param player LuaPlayer
local function toggle_interface(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local main_frame = player_global.view.main_frame
    if main_frame == nil then
        player.opened = player_global.view.main_frame
        build_interface(player)
    else
        local modal_main_frame = player_global.view.modal_main_frame
        if modal_main_frame then
            main_frame.ignored_by_interaction = true
        else
            player_global.model.last_gui_location = main_frame.location
            main_frame.destroy()
            player_global.view = globals.get_empty_player_view()
        end
    end
end

---@param player LuaPlayer
---@param modal_function string?
---@param args table?
function toggle_modal(player, modal_function, args)
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
        if not modal_function then return end
        modal.build_modal(player, modal_function, args)
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
    toggle_interface(player)
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
                slider_textfield.update_slider_value(fuel_category_slider_textfield_flow, fuel_config:get_max_fuel_amount())
            end

            settings_tab_view.build_settings_tab(player)

        elseif action == constants.actions.train_report_update then
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.close_window then
            toggle_interface(player)

        elseif action == constants.actions.exclude_textfield_apply then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.excluded_keywords:set_enabled(text, true)
                keyword_tabs_view.build_exclude_tab(player)
                display_tab_view.build_display_tab(player)
            end

        elseif action == constants.actions.delete_excluded_keyword then
            local excluded_keyword = event.element.tags.keyword
            if type(excluded_keyword) ~= "string" then return end
            player_global.model.excluded_keywords:remove_item(excluded_keyword)
            keyword_tabs_view.build_exclude_tab(player)
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.delete_all_excluded_keywords then

            player_global.model.excluded_keywords:remove_all()
            keyword_tabs_view.build_exclude_tab(player)
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.hide_textfield_apply then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.hidden_keywords:set_enabled(text, true)
                keyword_tabs_view.build_hide_tab(player)
                display_tab_view.build_display_tab(player)
            end

        elseif action == constants.actions.delete_hidden_keyword then
            local hidden_keyword = event.element.tags.keyword
            if type(hidden_keyword) ~= "string" then return end
            player_global.model.hidden_keywords:remove_item(hidden_keyword)
            keyword_tabs_view.build_hide_tab(player)
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.delete_all_hidden_keywords then
            player_global.model.hidden_keywords:remove_all()
            keyword_tabs_view.build_hide_tab(player)
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.train_schedule_create_blueprint then
            local template_train
            local template_train_ids = event.element.tags.template_train_ids
            if type(template_train_ids) ~= "table" then return end
            for _, id in pairs(template_train_ids) do
                local template_option = schedule_report_table_scripts.get_train_by_id(id)
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

        elseif action == constants.actions.set_blueprint_orientation then
            local orientation = event.element.tags.orientation
            if type(orientation) ~= "number" then return end
            player_global.model.blueprint_configuration:set_new_blueprint_orientation(orientation)
            settings_tab_view.build_settings_tab(player)

        elseif action == constants.actions.open_modal then
            local modal_function = event.element.tags.modal_function
            local args = event.element.tags.args
            if not modal_function then return end
            if type(modal_function) ~= "string" or not constants.modal_functions[modal_function] then return end
            if type(args) ~= "table" and args ~= nil then return end
            toggle_modal(player, modal_function, args)

        elseif action == constants.actions.close_modal then
            toggle_modal(player)

        elseif action == constants.actions.import_keywords_button then
            local textfield_flow = event.element.parent
            if not textfield_flow then return end
            local text = textfield_flow["textfield"].text
            if text == "" then return end -- don't allow user to input the empty string
            textfield_flow["textfield"].text = ""
            if not event.element.tags.keywords then return end
            local keywords_tag = event.element.tags.keywords
            local keyword_list
            if keywords_tag == constants.keyword_lists.exclude then keyword_list = player_global.model.excluded_keywords
            elseif keywords_tag == constants.keyword_lists.hide then keyword_list = player_global.model.hidden_keywords
            end

            keyword_list:add_from_serialized(text)


            if keywords_tag == constants.keyword_lists.exclude then keyword_tabs_view.build_exclude_tab(player)
            elseif keywords_tag == constants.keyword_lists.hide then keyword_tabs_view.build_hide_tab(player)
            end

        elseif action == constants.actions.focus_modal then
            local modal_main_frame = player_global.view.modal_main_frame
            if modal_main_frame then
                player.opened = modal_main_frame
                modal_main_frame.bring_to_front()
            end
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
            keyword_tabs_view.build_exclude_tab(player)
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.toggle_hidden_keyword then
            local keyword = event.element.tags.keyword
            if type(keyword) ~= "string" then return end
            player_global.model.hidden_keywords:toggle_enabled(keyword)
            keyword_tabs_view.build_hide_tab(player)
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.toggle_current_surface then
            player_global.model.schedule_table_configuration:toggle_current_surface()
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.toggle_show_satisfied then
            player_global.model.schedule_table_configuration:toggle_show_satisfied()
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.toggle_show_invalid then
            player_global.model.schedule_table_configuration:toggle_show_invalid()
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.toggle_blueprint_snap then
            player_global.model.blueprint_configuration:toggle_blueprint_snap()
            settings_tab_view.build_settings_tab(player)

        elseif action == constants.actions.toggle_place_trains_with_fuel then
            player_global.model.fuel_configuration:toggle_add_fuel()
            settings_tab_view.build_settings_tab(player)
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
        if action == constants.actions.exclude_textfield_apply then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.excluded_keywords:set_enabled(text, true)
                keyword_tabs_view.build_exclude_tab(player)
                display_tab_view.build_display_tab(player)
            end
        elseif action == constants.actions.hide_textfield_apply then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.hidden_keywords:set_enabled(text, true)
                keyword_tabs_view.build_hide_tab(player)
                display_tab_view.build_display_tab(player)
            end
        end
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

    global.model = {
        fuel_category_data = fuel_category_data.get_fuel_category_data()
    }

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
    if not global.model then global.model = {} end
    global.model.fuel_category_data = fuel_category_data.get_fuel_category_data()

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
