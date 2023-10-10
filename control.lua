local constants = require("constants")
local utils = require("utils")
local globals = require("scripts.globals")

-- Models
local fuel_category_data = require("models.fuel_category_data")

-- view
local blueprint_orientation_selector = require("views.settings_views.blueprint_orientation_selector")
local blueprint_snap_selection = require("views/settings_views/blueprint_snap_selection")
local slider_textfield = require("views/slider_textfield")
local icon_selector_textfield = require("views/icon_selector_textfield")
local keyword_tables = require("views/keyword_tables")

local display_tab_view = require("views/display_tab")

-- scripts

local schedule_report_table_scripts = require("scripts/schedule_report_table")

local function build_exclude_tab(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local exclude_content_frame = player_global.view.exclude_content_frame
    if not exclude_content_frame then return end
    exclude_content_frame.clear()

    local exclude_control_flow = exclude_content_frame.add{type="flow", direction="vertical", style="tll_controls_flow"}
    exclude_control_flow.style.bottom_margin = 5
    exclude_control_flow.add{type="label", caption={"tll.add_excluded_keyword"}, tooltip={"tll.add_excluded_keyword_tooltip"}}
    local exclude_textfield_flow = exclude_control_flow.add{type="flow", direction="horizontal"}
    icon_selector_textfield.build_icon_selector_textfield(exclude_textfield_flow, {"tll.apply_change"}, constants.actions.exclude_textfield_apply)
    local spacer = exclude_textfield_flow.add{type="empty-widget"}
    spacer.style.horizontally_stretchable = true
    exclude_textfield_flow.add{type="sprite-button", tags={action=constants.actions.delete_all_excluded_keywords}, style="tool_button_red", sprite="utility/trash", tooltip={"tll.delete_all_keywords"}}


    local excluded_keywords_frame = exclude_content_frame.add{type="scroll-pane", direction="vertical"}
    excluded_keywords_frame.style.vertically_stretchable = true
    player_global.view.excluded_keywords_frame = excluded_keywords_frame

    keyword_tables.build_excluded_keyword_table(player_global, player_global.model.excluded_keywords)

end

-- TODO: merge a lot of this logic with exclude? building of apply textfield, at least?
local function build_hide_tab(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local hide_content_frame = player_global.view.hide_content_frame
    if not hide_content_frame then return end

    hide_content_frame.clear()
    local control_flow = hide_content_frame.add{type="flow", direction="vertical", style="tll_controls_flow"}
    control_flow.style.bottom_margin = 5
    control_flow.add{type="label", caption={"tll.add_hidden_keyword"}, tooltip={"tll.add_hidden_keyword_tooltip"}}
    local textfield_flow = control_flow.add{type="flow", direction="horizontal"}
    icon_selector_textfield.build_icon_selector_textfield(textfield_flow, {"tll.apply_change"}, constants.actions.hide_textfield_apply)
    local spacer = textfield_flow.add{type="empty-widget"}
    spacer.style.horizontally_stretchable = true
    textfield_flow.add{type="sprite-button", tags={action=constants.actions.delete_all_hidden_keywords}, style="tool_button_red", sprite="utility/trash", tooltip={"tll.delete_all_keywords"}}

    local hidden_keywords_frame = hide_content_frame.add{type="scroll-pane", direction="vertical"}
    hidden_keywords_frame.style.vertically_stretchable = true
    player_global.view.hidden_keywords_frame = hidden_keywords_frame

    keyword_tables.build_hidden_keyword_table(player_global, player_global.model.hidden_keywords)

end

local function build_settings_tab(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local settings_content_frame = player_global.view.settings_content_frame
    if not settings_content_frame then return end

    settings_content_frame.clear()

    local blueprint_config = player_global.model.blueprint_configuration

    local scroll_pane = settings_content_frame.add{type="scroll-pane", direction="vertical"}
    scroll_pane.style.vertically_stretchable = true

    -- blueprint settings
    local blueprint_settings_frame = scroll_pane.add{type="frame", style="bordered_frame", direction="vertical"}

    local blueprint_header_label = blueprint_settings_frame.add{
        type="label",
        style="bold_label",
        caption={"tll.blueprint_settings"},
        tooltip={"tll.blueprint_settings_tooltip"}
    }
    blueprint_header_label.style.font_color={1, 0.901961, 0.752941}
    blueprint_orientation_selector.build_blueprint_orientation_selector(blueprint_config.new_blueprint_orientation, blueprint_settings_frame)
    blueprint_snap_selection.build_blueprint_snap_selector(player, blueprint_settings_frame)

    -- fuel settings
    local fuel_settings_frame = scroll_pane.add{type="frame", style="bordered_frame", direction="vertical"}

    local fuel_header_label = fuel_settings_frame.add{
        type="label",
        style="bold_label",
        caption={"tll.fuel_settings"},
        tooltip={"tll.fuel_settings_tooltip"}
    }
    fuel_header_label.style.font_color={1, 0.901961, 0.752941}

    local fuel_config = player_global.model.fuel_configuration

    fuel_settings_frame.add{
        type="checkbox",
        tags={action=constants.actions.toggle_place_trains_with_fuel},
        state=fuel_config.add_fuel,
        caption={"tll.place_trains_with_fuel_checkbox"}
    }

    fuel_category_table = fuel_settings_frame.add{type="table", column_count=3}

    for fuel_category, fuel_category_config in pairs(fuel_config.fuel_category_configurations) do

        fuel_category_table.add{type="label", caption={"", "'", fuel_category, "'"}}
        local spacer = fuel_category_table.add{type="empty-widget"}
        spacer.style.horizontally_stretchable = true

        local category_settings_flow = fuel_category_table.add{type="flow", direction="vertical"}

        local fuel_amount_frame_enabled = fuel_config.add_fuel and fuel_category_config.selected_fuel ~= nil

        local maximum_fuel_amount = fuel_category_config:get_max_fuel_amount()

        local slider_value_step = maximum_fuel_amount % 10 == 0 and maximum_fuel_amount / 10 or 1

        local fuel_category_slider_textfield = slider_textfield.add_slider_textfield(
            category_settings_flow,
            {
                action=constants.actions.update_fuel_amount,
                fuel_category=fuel_category,
            },
            fuel_category_config.fuel_amount,
            slider_value_step,
            0,
            maximum_fuel_amount,
            fuel_amount_frame_enabled,
            true
        )

        player_global.view.fuel_amount_flows[fuel_category] = fuel_category_slider_textfield

        local valid_fuels = global.model.fuel_category_data.fuel_categories_and_fuels[fuel_category]

        local column_count = #valid_fuels < 10 and #valid_fuels or 10

        local table_frame = category_settings_flow.add{type="frame", style="slot_button_deep_frame"}
        local fuel_button_table = table_frame.add{type="table", column_count=column_count, style="filter_slot_table"}

        for _, fuel in pairs(valid_fuels) do
            local fuel_proto = game.item_prototypes[fuel]
            local localized_name = fuel_proto.localised_name
            local fuel_value = fuel_proto.fuel_value
            local fuel_acceleration_multiplier = fuel_proto.fuel_acceleration_multiplier
            local fuel_top_speed_multiplier = fuel_proto.fuel_top_speed_multiplier
            local fuel_burnt_result = fuel_proto.burnt_result
            local fuel_burnt_result_text
            if fuel_burnt_result then
                fuel_burnt_result_text = {
                    "",
                    "[img=item." .. fuel_burnt_result.name .. "] ",
                    fuel_burnt_result.localised_name
                }
            end

            local tooltip = {
                "",
                {"tll.tooltip_title", localized_name},
                {"tll.attribute_line", {"tll.fuel_value"}, utils.localize_to_metric(fuel_value, "J", 2)},
                {"tll.attribute_line", {"tll.vehicle_acceleration"}, utils.localize_to_percentage(fuel_acceleration_multiplier, 0)},
                {"tll.attribute_line", {"tll.vehicle_top_speed"}, utils.localize_to_percentage(fuel_top_speed_multiplier, 0)},
                fuel_burnt_result and {"tll.attribute_line", {"tll.spent_result"}, fuel_burnt_result_text} or "",

            }

            local button_style = (fuel == fuel_category_config.selected_fuel) and "yellow_slot_button" or "recipe_slot_button"
            fuel_button_table.add{
                type="sprite-button",
                sprite=("item/" .. fuel),
                tags={
                    action=constants.actions.select_fuel,
                    item_name=fuel,
                    fuel_category=fuel_category
                },
                style=button_style,
                enabled=fuel_config.add_fuel,
                tooltip=tooltip
            }
        end 
    end
end

---@param player LuaPlayer
local function build_interface(player)
    ---@TLLPlayerGlobal
    local player_global = global.players[player.index]

    local screen_element = player.gui.screen

    local main_frame = screen_element.add{type="frame", name="tll_main_frame", direction="vertical"}
    main_frame.style.size = {600, 800}

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

    build_exclude_tab(player)

    -- hide tab
    local hide_tab = tabbed_pane.add{type="tab", caption={"tll.hide_tab"}}
    local hide_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="tll_tab_content_frame"}
    tabbed_pane.add_tab(hide_tab, hide_content_frame)
    player_global.view.hide_content_frame = hide_content_frame

    build_hide_tab(player)

    -- settings tab
    local settings_tab = tabbed_pane.add{type="tab", caption={"tll.settings_tab"}}
    local settings_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="tll_tab_content_frame"}
    tabbed_pane.add_tab(settings_tab, settings_content_frame)

    player_global.view.settings_content_frame = settings_content_frame

    build_settings_tab(player)

end

local function toggle_interface(player)

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local main_frame = player_global.view.main_frame
    if main_frame == nil then
        player.opened = player_global.view.main_frame
        build_interface(player)
    else
        player_global.model.last_gui_location = main_frame.location
        main_frame.destroy()
        player_global.view = globals.get_empty_player_view()
    end
end

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

            build_settings_tab(player)

        elseif action == constants.actions.train_report_update then
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.close_window then
            toggle_interface(player)

        elseif action == constants.actions.exclude_textfield_apply then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.excluded_keywords:set_enabled(text, true)
                keyword_tables.build_excluded_keyword_table(player_global, player_global.model.excluded_keywords)
                display_tab_view.build_display_tab(player)
            end

        elseif action == constants.actions.delete_excluded_keyword then
            local excluded_keyword = event.element.tags.keyword
            if type(excluded_keyword) ~= "string" then return end
            player_global.model.excluded_keywords:remove_item(excluded_keyword)
            keyword_tables.build_excluded_keyword_table(player_global, player_global.model.excluded_keywords)
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.delete_all_excluded_keywords then

            player_global.model.excluded_keywords:remove_all()
            keyword_tables.build_excluded_keyword_table(player_global, player_global.model.excluded_keywords)
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.hide_textfield_apply then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.hidden_keywords:set_enabled(text, true)
                keyword_tables.build_hidden_keyword_table(player_global, player_global.model.hidden_keywords)
                display_tab_view.build_display_tab(player)
            end

        elseif action == constants.actions.delete_hidden_keyword then
            local hidden_keyword = event.element.tags.keyword
            if type(hidden_keyword) ~= "string" then return end
            player_global.model.hidden_keywords:remove_item(hidden_keyword)
            keyword_tables.build_hidden_keyword_table(player_global, player_global.model.hidden_keywords)
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.delete_all_hidden_keywords then
            player_global.model.hidden_keywords:remove_all()
            keyword_tables.build_hidden_keyword_table(player_global, player_global.model.hidden_keywords)
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
            build_settings_tab(player)
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
            keyword_tables.build_excluded_keyword_table(player_global, player_global.model.excluded_keywords)
            display_tab_view.build_display_tab(player)

        elseif action == constants.actions.toggle_hidden_keyword then
            local keyword = event.element.tags.keyword
            if type(keyword) ~= "string" then return end
            player_global.model.hidden_keywords:toggle_enabled(keyword)
            keyword_tables.build_hidden_keyword_table(player_global, player_global.model.hidden_keywords)
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
            build_settings_tab(player)

        elseif action == constants.actions.toggle_place_trains_with_fuel then
            player_global.model.fuel_configuration:toggle_add_fuel()
            build_settings_tab(player)
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

script.on_event(defines.events.on_gui_closed, function(event)
    if event.element then
        local player = game.get_player(event.player_index)
        if event.element.name == "tll_main_frame" then
            toggle_interface(player)
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
                keyword_tables.build_excluded_keyword_table(player_global, player_global.model.excluded_keywords)
                display_tab_view.build_display_tab(player)
            end
        elseif action == constants.actions.hide_textfield_apply then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.hidden_keywords:set_enabled(text, true)
                keyword_tables.build_hidden_keyword_table(player_global, player_global.model.hidden_keywords)
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
