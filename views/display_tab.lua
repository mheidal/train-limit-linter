local constants = require("constants")
local utils = require("utils")

local schedule_report_table_scripts = require("scripts.schedule_report_table")

local Exports = {}

---@param player LuaPlayer
local function build_train_schedule_group_report(player)

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local surface_train_schedule_groups_pairs = schedule_report_table_scripts.get_train_schedule_groups_by_surface()
    local report_frame = player_global.view.report_frame
    if not report_frame then return end
    report_frame.clear()

    local enabled_excluded_keywords = player_global.model.excluded_keywords:get_enabled_keywords()
    local enabled_hidden_keywords = player_global.model.hidden_keywords:get_enabled_keywords()

    local rails_under_trains_without_schedules = schedule_report_table_scripts.get_rails_to_trains_without_schedule()

    local table_config = player_global.model.schedule_table_configuration

    local column_count = 4
    column_count = column_count + (table_config.show_all_surfaces and 1 or 0)
    column_count = column_count + (table_config.show_manual and 1 or 0)

    local any_schedule_shown = false

    local schedule_report_table = report_frame.add{type="table", style="bordered_table", column_count=column_count}
    schedule_report_table.style.maximal_width = 552

    if table_config.show_all_surfaces then
        schedule_report_table.add{type="label", caption={"tll.surface_header"}}
    end

    local schedule_header_flow = schedule_report_table.add{type="flow", direction="horizontal", style="tll_horizontal_stretch_squash_flow"}
    schedule_header_flow.add{type="label", caption={"tll.schedule_header"}}
    schedule_header_flow.add{type="empty-widget"}
        schedule_header_flow.style.maximal_width = 300

    schedule_report_table.add{type="label", caption={"tll.train_count_header"}}
    schedule_report_table.add{type="label", caption={"tll.sum_of_limits_header"}}
    schedule_report_table.add{type="empty-widget"}

    if table_config.show_manual then
        schedule_report_table.add{type="label", caption={"tll.manual_header"}}
    end

    for _, surface_train_schedule_groups_pair in pairs(surface_train_schedule_groups_pairs) do
        local surface = surface_train_schedule_groups_pair.surface

        -- barrier for all train schedules for a surface
        if table_config.show_all_surfaces or surface.name == player.surface.name then
            local train_schedule_groups = surface_train_schedule_groups_pair.train_schedule_groups

            local sorted_schedule_names = {}
            for schedule_name, _ in pairs(train_schedule_groups) do table.insert(sorted_schedule_names, schedule_name) end
            table.sort(sorted_schedule_names)

            for _, schedule_name in pairs(sorted_schedule_names) do

                local train_schedule_group = train_schedule_groups[schedule_name]
                local train_stop_data = schedule_report_table_scripts.get_train_stop_data(train_schedule_group, surface, enabled_excluded_keywords, enabled_hidden_keywords, rails_under_trains_without_schedules)

                local satisfied = (not (train_stop_data.dynamic or train_stop_data.not_set)) and (train_stop_data.limit - #train_schedule_group == 1)

                local single_station_schedule = #train_schedule_group[1].schedule.records == 1

                -- barrier for showing a particular schedule
                if (
                    (not train_stop_data.hidden)
                    and (table_config.show_satisfied or (not satisfied))
                    and (table_config.show_not_set or (not train_stop_data.not_set))
                    and (table_config.show_dynamic or (not train_stop_data.dynamic))
                    and (table_config.show_single_station_schedules or (not single_station_schedule))
                ) then
                    any_schedule_shown = true

                    local train_limit_sum_caption = {
                        "",
                        tostring(train_stop_data.limit),
                        (train_stop_data.not_set or train_stop_data.dynamic) and {"tll.warning_icon"} or "",
                    }
                    local train_limit_sum_tooltip = {
                        "",
                        train_stop_data.not_set and {"tll.train_limit_not_set_tooltip"} or "",
                        train_stop_data.not_set and train_stop_data.dynamic and "\n" or "",
                        train_stop_data.dynamic and {"tll.train_limit_dynamic_tooltip"} or "",
                    }

                    local show_opinionation = not train_stop_data.not_set and not train_stop_data.dynamic and not single_station_schedule

                    local train_count_difference = train_stop_data.limit - 1 - #train_schedule_group

                    -- caption
                    local train_count_caption = tostring(#train_schedule_group)
                    if show_opinionation and train_count_difference ~= 0 then
                        local diff_str = train_count_difference > 0 and "+" or ""
                        train_count_caption = train_count_caption .. " (" .. diff_str .. tostring(train_count_difference) .. ") [img=info]"
                    end

                    -- tooltip
                    local recommended_action_tooltip = nil
                    if show_opinionation and train_count_difference ~= 0 then
                        local abs_diff = math.abs( train_count_difference)
                        recommended_action_tooltip = train_count_difference > 0 and {"tll.add_n_trains_tooltip", abs_diff} or {"tll.remove_n_trains_tooltip", abs_diff}
                    end

                    -- color
                    local train_count_label_color
                    if show_opinionation then
                        if train_count_difference ~= 0 then
                            train_count_label_color = {1, 0.541176, 0.541176}
                        else
                            train_count_label_color = {0.375, 0.703125, 0.390625} -- copied from "confirm" buttons in game
                        end
                    else
                        train_count_label_color = {1, 1, 1}
                    end

                    local template_train_ids = {}
                    for _, train in pairs(train_schedule_group) do
                        table.insert(template_train_ids, train.id)
                    end

                    local manual_train_ids = {}
                    for _, train in pairs(train_schedule_group) do
                        if train.manual_mode then
                            table.insert(manual_train_ids, train.id)
                        end
                    end

                    -- cell 1
                    if table_config.show_all_surfaces then
                        schedule_report_table.add{type="label", caption=surface.name}
                    end


                    -- cell 2
                    local schedule_cell = schedule_report_table.add{
                        type="flow",
                        direction="horizontal",
                        style="tll_horizontal_stretch_squash_flow"
                    }
                    local schedule_cell_label = schedule_cell.add{
                        type="label",
                        caption=schedule_name,
style="tll_horizontal_stretch_squash_label"
                    }
                    schedule_cell_label.style.font_color=train_count_label_color

                    schedule_cell.add{type="empty-widget"}
                    schedule_cell.style.maximal_width = 300


                    -- cell 3
                    local train_count_cell = schedule_report_table.add{
                        type="label",
                        caption=train_count_caption,
                        tooltip=recommended_action_tooltip
                    }
                    train_count_cell.style.font_color=train_count_label_color

                    -- cell 4
                    schedule_report_table.add{type="label", caption=train_limit_sum_caption, tooltip=train_limit_sum_tooltip}

                    local any_trains_with_no_schedule_parked = utils.get_table_size(train_stop_data.trains_with_no_schedule_parked) > 0
                    local parked_train_positions_and_train_stops = {}
                    for _, parked_train_and_train_stop in pairs(train_stop_data.trains_with_no_schedule_parked) do
                        table.insert(parked_train_positions_and_train_stops, {
                            position=parked_train_and_train_stop.train.front_stock.position,
                            train_stop=parked_train_and_train_stop.train_stop
                        })
                    end

                    -- cell 5

                    local copy_sprite = any_trains_with_no_schedule_parked and "utility/warning_icon" or "utility/copy"
                    local copy_tooltip = {
                        "",
                        {"tll.copy_train_blueprint_tooltip"},
                        any_trains_with_no_schedule_parked and {"tll.copy_train_blueprint_tooltip_parked_train", #parked_train_positions_and_train_stops} or ""
                    }

                    local copy_tags = {
                        action=any_trains_with_no_schedule_parked and constants.actions.train_schedule_create_blueprint_and_ping_trains or constants.actions.train_schedule_create_blueprint,
                        template_train_ids=template_train_ids,
                        surface=surface.name,
                        parked_train_positions=any_trains_with_no_schedule_parked and parked_train_positions_and_train_stops or nil
                    }


                    schedule_report_table.add{
                        type="sprite-button",
                        sprite=copy_sprite,
                        style="tool_button_blue",
                        tags=copy_tags,
                        tooltip=copy_tooltip,
                    }

                    -- cell 6
                    if table_config.show_manual then
                        if #manual_train_ids > 0 then
                            schedule_report_table.add{
                                type="sprite-button",
                                caption=tostring(#manual_train_ids),
                                style="tool_button_red",
                                tags={
                                    action=constants.actions.train_schedule_ping_manual_trains,
                                    manual_train_ids=manual_train_ids,
                                    surface=surface.name,
                                    schedule_name=schedule_name,
                                },
                                tooltip={"tll.list_manual_trains"}
                            }
                        else
                            schedule_report_table.add{
                                type="label",
                                caption=tostring(#manual_train_ids),
                                tooltip={"tll.no_manual_trains"}
                            }
                        end

                    end
                end
            end
        end
    end

    if not any_schedule_shown then
        schedule_report_table.visible = false
        local no_schedules_label = report_frame.add{type="label", caption={"tll.no_schedules"}}
        no_schedules_label.style.horizontally_stretchable = true
        no_schedules_label.style.margin = 12
    end
end

function Exports.build_display_tab(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local display_content_frame = player_global.view.display_content_frame
    if not display_content_frame then return end

    local table_config = player_global.model.schedule_table_configuration

    local controls_frame_name = "controls_frame"
    local controls_frame = display_content_frame[controls_frame_name] or display_content_frame.add{
        type="frame",
        name=controls_frame_name,
        direction="vertical",
        style="subpanel_frame"
    }
    controls_frame.style.horizontally_stretchable = true

    controls_frame.clear()

    local show_hide_flow = controls_frame.add{
        type="flow",
        direction="horizontal",
        style="player_input_horizontal_flow",
    }

    local show_hide_button_sprite = table_config.show_settings and "utility/collapse" or "utility/expand"
    local show_hide_button_hovered_sprite = table_config.show_settings and "utility/collapse_dark" or "utility/expand_dark"

    show_hide_flow.add{
        type="sprite-button",
        style="control_settings_section_button",
        tags={action=constants.actions.toggle_show_settings},
        sprite=show_hide_button_sprite,
        hovered_sprite=show_hide_button_hovered_sprite,
    }

    show_hide_flow.add{type="label", style="caption_label", caption={"tll.tooltip_title", {"tll.display_settings"}}}

    local controls_flow = controls_frame.add{
        type="flow",
        direction="vertical",
        style="tll_controls_flow",
        visible=table_config.show_settings,
    }

    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_all_surfaces}, caption={"tll.show_all_surfaces"}, state=table_config.show_all_surfaces}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_satisfied}, caption={"tll.show_satisfied"}, state=table_config.show_satisfied}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_not_set}, caption={"tll.show_not_set"}, state=table_config.show_not_set}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_dynamic}, caption={"tll.show_dynamic"}, state=table_config.show_dynamic}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_manual}, caption={"tll.show_manual"}, state=table_config.show_manual}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_single_station_schedules}, caption={"tll.show_single_station_schedules"}, state=table_config.show_single_station_schedules}

    local report_frame_name = "report_frame_name"

    local report_frame = display_content_frame[report_frame_name] or display_content_frame.add{
        type="scroll-pane",
        name="report_frame_name",
        direction="vertical",
        style="tll_content_scroll_pane",
        vertical_scroll_policy="auto-and-reserve-space"
    }
    report_frame.style.top_margin = 12
    report_frame.clear()
    player_global.view.report_frame = report_frame
    build_train_schedule_group_report(player)
end

return Exports