local constants = require("constants")
local utils = require("utils")

local collapsible_frame = require("views.collapsible_frame")
local blueprint_orientation_selector = require("views.settings_views.blueprint_orientation_selector")
local blueprint_snap_selection = require("views.settings_views.blueprint_snap_selection")
local slider_textfield = require("views.slider_textfield")
local train_removal_buttons = require("views.train_removal_radio_buttons")

Exports = {}

function Exports.build_settings_tab(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local gui_config = player_global.model.gui_configuration

    local element_names = constants.gui_element_names.settings_tab

    local settings_content_frame = player_global.view.settings_content_frame
    if not settings_content_frame then return end

    local scroll_pane = settings_content_frame[element_names.scroll_pane] or settings_content_frame.add{
        type="scroll-pane",
        direction="vertical",
        name=element_names.scroll_pane,
        style="tll_content_scroll_pane",
        vertical_scroll_policy="auto-and-reserve-space",
    }
    scroll_pane.clear()

    -- blueprint settings
    do
        local blueprint_config = player_global.model.blueprint_configuration

        local blueprint_collapsible_frame = scroll_pane[element_names.blueprint_collapsible_frame] or collapsible_frame.build_collapsible_frame(
            scroll_pane,
            element_names.blueprint_collapsible_frame
        )
        local blueprint_content_flow = collapsible_frame.build_collapsible_frame_contents(
            blueprint_collapsible_frame,
            constants.actions.toggle_blueprint_settings_visible,
            {"tll.blueprint_settings"},
            {"tll.blueprint_settings_tooltip"},
            gui_config.collapsible_frame_configuration.blueprint_settings_visible
        )

        blueprint_orientation_selector.build_blueprint_orientation_selector(blueprint_config.new_blueprint_orientation, blueprint_content_flow)

        blueprint_content_flow.add{type="line"}

        blueprint_snap_selection.build_blueprint_snap_selector(player, blueprint_content_flow)

        blueprint_content_flow.add{type="line"}

        blueprint_content_flow.add{
            type="checkbox",
            tags={action=constants.actions.toggle_include_train_stops},
            state=blueprint_config.include_train_stops,
            caption={"tll.include_train_stops"},
            tooltip={"tll.include_train_stops_tooltip"}
        }

        blueprint_content_flow.add{
            type="checkbox",
            tags={action=constants.actions.toggle_limit_train_stops},
            state=blueprint_config.limit_train_stops,
            enabled=blueprint_config.include_train_stops,
            caption={"tll.limit_train_stops"},
        }

        local default_train_limit_table = blueprint_content_flow.add{type="table", column_count=2}
        local default_train_limit_label = default_train_limit_table.add{type="label", caption="Set default train limit"}
        default_train_limit_label.style.single_line = false
        default_train_limit_label.style.width = 180

        slider_textfield.add_slider_textfield(
            default_train_limit_table,
            {action=constants.actions.set_default_train_limit},
            blueprint_config.default_train_limit,
            1,
            0,
            10,
            blueprint_config.include_train_stops and blueprint_config.limit_train_stops,
            false
        )
    end

    -- fuel settings

    do
        local fuel_collapsible_frame = scroll_pane[element_names.fuel_collapsible_frame] or collapsible_frame.build_collapsible_frame(
            scroll_pane,
            element_names.fuel_collapsible_frame
        )
        local fuel_content_flow = collapsible_frame.build_collapsible_frame_contents(
            fuel_collapsible_frame,
            constants.actions.toggle_fuel_settings_visible,
            {"tll.fuel_settings"},
            {"tll.fuel_settings_tooltip"},
            gui_config.collapsible_frame_configuration.fuel_settings_visible
        )

        local fuel_config = player_global.model.fuel_configuration

        fuel_content_flow.add{
            type="checkbox",
            tags={action=constants.actions.toggle_place_trains_with_fuel},
            state=fuel_config.add_fuel,
            caption={"tll.place_trains_with_fuel_checkbox"}
        }

        fuel_category_table = fuel_content_flow.add{type="table", column_count=2, style="bordered_table"}

        for fuel_category, fuel_category_config in pairs(fuel_config.fuel_category_configurations) do
            if not game.fuel_category_prototypes[fuel_category] then goto fuel_category_continue end

            local fuel_category_caption = {"tll.fuel_category_caption", game.fuel_category_prototypes[fuel_category].localised_name}

            local locomotive_consumers = {}
            for locomotive, fuel_categories in pairs(global.model.fuel_category_data.locomotives_fuel_categories) do
                if utils.contains(fuel_categories, fuel_category) then
                    table.insert(locomotive_consumers, locomotive)
                end
            end
            local tooltip_title = {"tll.tooltip_title", {"tll.fuel_category_consumed_by"}}
            local locomotive_consumer_tooltip = {"", tooltip_title}
            for _, locomotive_consumer in pairs(locomotive_consumers) do
                table.insert(locomotive_consumer_tooltip, {"", "\n[img=entity." .. locomotive_consumer .. "] ", (game.entity_prototypes[locomotive_consumer].localised_name or locomotive_consumer)})
            end

            local valid_fuels = global.model.fuel_category_data.fuel_categories_and_fuels[fuel_category]
            if not valid_fuels[1] then goto fuel_category_continue end -- check if list of valid fuels is empty

            local fuel_category_label = fuel_category_table.add{type="label", caption=fuel_category_caption, tooltip=locomotive_consumer_tooltip}
            fuel_category_label.style.width = 160 -- 1/3 the table's width, ish

            local category_settings_flow = fuel_category_table.add{type="flow", direction="vertical"}

            local fuel_amount_frame_enabled = fuel_config.add_fuel and fuel_category_config.selected_fuel ~= nil

            local maximum_fuel_amount = fuel_category_config:get_fuel_stack_size() * global.model.fuel_category_data.maximum_fuel_slot_count

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

            local max_column_count = 8
            local column_count = #valid_fuels < max_column_count and #valid_fuels or max_column_count

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
            ::fuel_category_continue::
        end

    end

    -- general settings
    do
        local general_collapsible_frame = scroll_pane[element_names.general_collapsible_frame] or collapsible_frame.build_collapsible_frame(
            scroll_pane,
            element_names.general_collapsible_frame
        )
        local general_content_flow = collapsible_frame.build_collapsible_frame_contents(
            general_collapsible_frame,
            constants.actions.toggle_general_settings_visible,
            {"tll.general_settings"},
            {"tll.general_settings"},
            gui_config.collapsible_frame_configuration.general_settings_visible
        )
        local general_config = player_global.model.general_configuration

        local remove_train_options_flow = general_content_flow.add{type="flow", direction="vertical"}
        train_removal_buttons.add_train_removal_radio_buttons(remove_train_options_flow, general_config)

        general_content_flow.add{type="line"}

        general_content_flow.add{
            type="checkbox",
            tags={action=constants.actions.toggle_ignore_stations_with_dynamic_limits},
            state=general_config.ignore_stations_with_dynamic_limits,
            caption={"tll.ignore_stations_with_dynamic_limits"}
        }
    end

    -- other mods settings
    do
        local other_mods_collapsible_frame = scroll_pane[element_names.other_mods_collapsible_frame] or collapsible_frame.build_collapsible_frame(
            scroll_pane,
            element_names.other_mods_collapsible_frame
        )
        local other_mods_content_flow = collapsible_frame.build_collapsible_frame_contents(
            other_mods_collapsible_frame,
            constants.actions.toggle_other_mods_settings_visible,
            {"tll.other_mod_settings"},
            nil,
            gui_config.collapsible_frame_configuration.other_mods_settings_visible
        )
        local other_mods_config = player_global.model.other_mods_configuration
        local number_of_mods_shown = 0

        if remote.interfaces[constants.supported_interfaces.train_groups] then
            number_of_mods_shown = number_of_mods_shown + 1
            if number_of_mods_shown >= 2 then
                other_mods_content_flow.add{type="line"}
            end

            local TrainGroups_config = other_mods_config.TrainGroups_configuration
            local TrainGroups_flow = other_mods_content_flow.add{type="flow", direction="vertical"}
            TrainGroups_flow.add{type="label", style="caption_label", caption={"tll.TrainGroups"}}
            TrainGroups_flow.add{
                type="checkbox",
                caption={"tll.TrainGroups_copy_train_group"},
                state=TrainGroups_config.copy_train_group,
                tags={action=constants.actions.toggle_TrainGroups_copy_train_group},
            }
        end

        if number_of_mods_shown == 0 then
            other_mods_collapsible_frame.visible = false
        end

    end

end

return Exports