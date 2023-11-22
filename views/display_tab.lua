local constants = require("constants")
local utils = require("utils")

local schedule_report_table_scripts = require("scripts.schedule_report_table")

local collapsible_frame = require("views.collapsible_frame")

local Exports = {}

---@param player LuaPlayer
local function build_train_schedule_group_report(player)

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    local train_groups = schedule_report_table_scripts.get_train_groups(player_global.model.excluded_keywords, player_global.model.hidden_keywords)

    local report_frame = player_global.view.report_frame
    if not report_frame then return end
    report_frame.clear()

    local rails_under_trains_without_schedules = schedule_report_table_scripts.get_rails_to_trains_without_schedule()

    local table_config = player_global.model.schedule_table_configuration

    local column_count = 4
    column_count = column_count + (table_config.show_all_surfaces and 1 or 0)

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
    schedule_report_table.add{type="label", caption={"tll.actions_header"}}

    for surface, surface_train_groups in pairs(schedule_report_table_scripts.group_train_groups_by_surface(train_groups)) do

        -- barrier for all train schedules for a surface
        if table_config.show_all_surfaces or surface == player.surface.name then

            table.sort(surface_train_groups, function(a, b)
                return a.filtered_schedule.key < b.filtered_schedule.key
            end
            )

            for _, train_group in pairs(surface_train_groups) do
                ---@type ScheduleTableData
                local schedule_report_data = schedule_report_table_scripts.get_train_stop_data(
                    train_group,
                    surface,
                    rails_under_trains_without_schedules
                )

                local is_single_station_schedule = #train_group.filtered_schedule.records == 1

                local nonexistent_stations_in_schedule = {}
                local any_nonexistent_stations_in_schedule = false
                for _, record in pairs(train_group.filtered_schedule.records) do
                    if record.station and not schedule_report_data.train_stops[record.station] then
                        nonexistent_stations_in_schedule[record.station] = true
                        any_nonexistent_stations_in_schedule = true
                    end
                end

                local satisfied = (
                    not (
                            schedule_report_data.dynamic
                            or schedule_report_data.not_set
                            or is_single_station_schedule
                            or any_nonexistent_stations_in_schedule
                    )
                    and (
                            schedule_report_data.limit - #train_group.trains == 1
                    )
                )

                -- barrier for showing a particular schedule
                if (
                    (not schedule_report_data.hidden)
                    and (table_config.show_satisfied or (not satisfied))
                    and (table_config.show_not_set or (not schedule_report_data.not_set))
                    and (table_config.show_dynamic or (not schedule_report_data.dynamic))
                    and (table_config.show_single_station_schedules or (not is_single_station_schedule))
                ) then
                    any_schedule_shown = true

                    -- whether the schedule is valid for evaulation by P + R - 1
                    local schedule_valid = (
                        not schedule_report_data.not_set
                        and not schedule_report_data.dynamic
                        and not is_single_station_schedule
                        and not any_nonexistent_stations_in_schedule
                    )

                    -- whether the schedule should have any stated opinion (warnings, coloration)
                    local opinionate = player_global.model.schedule_table_configuration.opinionate

                    local sorted_all_schedules = {}
                    for key, schedule in pairs(train_group.all_schedules) do
                        sorted_all_schedules[#sorted_all_schedules+1] = schedule
                    end
                    table.sort(sorted_all_schedules, function (a, b)
                        return #a > #b
                    end)

                    local first_schedule = true
                    local schedule_caption
                    local schedule_caption_tooltip
                    for _, schedule in pairs(sorted_all_schedules) do
                        if first_schedule then
                            schedule_caption = schedule_report_table_scripts.generate_schedule_caption(
                                table_config,
                                schedule,
                                schedule_report_data,
                                player_global.model.excluded_keywords,
                                opinionate,
                                nonexistent_stations_in_schedule
                            )

                            if #sorted_all_schedules == 1 then
                                schedule_caption_tooltip = deep_copy(schedule_caption)
                            else
                                schedule_caption = {
                                    "",
                                    "[img=info] ",
                                    schedule_caption,
                                }
                                schedule_caption_tooltip = {"tll.multiple_matching_schedules"}
                            end

                            first_schedule = false
                        else
                            schedule_caption_tooltip = {
                                "",
                                schedule_caption_tooltip,
                                "\n",
                                schedule_report_table_scripts.generate_schedule_caption(
                                    table_config,
                                    schedule,
                                    schedule_report_data,
                                    player_global.model.excluded_keywords,
                                    opinionate,
                                    nonexistent_stations_in_schedule
                                )
                            }
                        end
                    end

                    for station, _ in pairs(nonexistent_stations_in_schedule) do
                        schedule_caption_tooltip = {"", schedule_caption_tooltip, {"tll.no_stations_with_name", station}}
                    end


                    local train_limit_sum_caption = {
                        "",
                        tostring(schedule_report_data.limit),
                        (opinionate and (schedule_report_data.not_set or schedule_report_data.dynamic)) and {"tll.warning_icon"} or "",
                    }

                    local train_limit_sum_tooltip = {
                        "",
                        opinionate and schedule_report_data.not_set and {"tll.train_limit_not_set_tooltip"} or "",
                        opinionate and schedule_report_data.not_set and schedule_report_data.dynamic and "\n" or "",
                        opinionate and schedule_report_data.dynamic and {"tll.train_limit_dynamic_tooltip"} or "",
                    }

                    local train_count_difference = schedule_report_data.limit - 1 - #train_group.trains

                    -- caption
                    local train_count_caption = tostring(#train_group.trains)
                    if schedule_valid and opinionate and train_count_difference ~= 0 then
                        local diff_str = train_count_difference > 0 and "+" or ""
                        train_count_caption = train_count_caption .. " (" .. diff_str .. tostring(train_count_difference) .. ") [img=info]"
                    end

                    -- tooltip
                    local recommended_action_tooltip = nil
                    if schedule_valid and opinionate and train_count_difference ~= 0 then
                        local abs_diff = math.abs( train_count_difference)
                        recommended_action_tooltip = train_count_difference > 0 and {"tll.add_n_trains_tooltip", abs_diff} or {"tll.remove_n_trains_tooltip", abs_diff}
                    end

                    -- color
                    local train_count_label_color
                    if schedule_valid and opinionate then
                        if train_count_difference ~= 0 then
                            train_count_label_color = {1, 0.541176, 0.541176}
                        else
                            train_count_label_color = {0.375, 0.703125, 0.390625} -- copied from "confirm" buttons in game
                        end
                    else
                        train_count_label_color = {1, 1, 1}
                    end

                    -- info about train stops this group visits

                    local template_train_stops = {}
                    for train_stop_name, train_stop_group_data in pairs(schedule_report_data.train_stops) do
                        table.insert(template_train_stops, {
                            name=train_stop_name,
                            color=train_stop_group_data[1].color,
                            proto_name=train_stop_group_data[1].proto_name,
                        })
                    end

                    -- cell 1
                    if table_config.show_all_surfaces then
                        schedule_report_table.add{type="label", caption=surface}
                    end


                    -- cell 2
                    local schedule_cell = schedule_report_table.add{
                        type="flow",
                        direction="horizontal",
                        style="tll_horizontal_stretch_squash_flow"
                    }
                    local schedule_cell_label = schedule_cell.add{
                        type="label",
                        caption=schedule_caption,
                        tooltip=schedule_caption_tooltip,
                        style="tll_horizontal_stretch_squash_label",
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

                    local any_trains_with_no_schedule_parked = utils.get_table_size(schedule_report_data.trains_with_no_schedule_parked) > 0
                    local parked_train_positions_and_train_stops = {}
                    for _, parked_train_and_train_stop in pairs(schedule_report_data.trains_with_no_schedule_parked) do
                        table.insert(parked_train_positions_and_train_stops, {
                            position=parked_train_and_train_stop.train.front_stock.position, ---@diagnostic disable-line
                            train_stop=parked_train_and_train_stop.train_stop ---@diagnostic disable-line
                        })
                    end

                    -- cell 5

                    local train_action_flow = schedule_report_table.add{type="flow", direction="horizontal"}

                    local copy_sprite = any_trains_with_no_schedule_parked and "utility/warning_icon" or "utility/copy"
                    local copy_tooltip = {
                        "",
                        {"tll.copy_train_blueprint_tooltip"},
                        any_trains_with_no_schedule_parked and {"tll.copy_train_blueprint_tooltip_parked_train", #parked_train_positions_and_train_stops} or ""
                    }

                    local copy_tags = {
                        action=any_trains_with_no_schedule_parked and constants.actions.train_schedule_create_blueprint_and_ping_trains or constants.actions.train_schedule_create_blueprint,
                        template_train_ids=train_group.trains,
                        surface=surface,
                        parked_train_positions=any_trains_with_no_schedule_parked and parked_train_positions_and_train_stops or nil,
                        template_train_stops=template_train_stops
                    }


                    train_action_flow.add{
                        type="sprite-button",
                        sprite=copy_sprite,
                        style="tool_button_blue",
                        tags=copy_tags,
                        tooltip=copy_tooltip,
                    }

                    local remove_tags = {
                        action=constants.actions.open_modal,
                        modal_function=constants.modal_functions.remove_trains,
                        args={
                            train_ids=train_group.trains,
                        },
                    }

                    local remove_tooltip = "Remove trains"
                    train_action_flow.add{
                        type="sprite-button",
                        sprite="utility/trash",
                        style="tool_button_red",
                        tags=remove_tags,
                        tooltip=remove_tooltip,
                    }
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

    local collapsible_frame_name = "display_collapsible_frame"
    local display_settings_collapsible_frame = display_content_frame[collapsible_frame_name] or collapsible_frame.build_collapsible_frame(
        display_content_frame,
        collapsible_frame_name
    )
    local collapsible_frame_content_flow = collapsible_frame.build_collapsible_frame_contents(
        display_settings_collapsible_frame,
        constants.actions.toggle_display_settings_visible,
        {"tll.display_settings"},
        nil,
        player_global.model.collapsible_frame_configuration.display_settings_visible
    )

    local controls_flow = collapsible_frame_content_flow.add{
        type="flow",
        direction="vertical",
        style="tll_controls_flow",
    }

    local function add_checkbox(action, caption, tooltip, state)
        controls_flow.add{type="checkbox", tags={action=action}, caption=caption, tooltip=tooltip, state=state}
    end

    add_checkbox(constants.actions.toggle_show_all_surfaces, {"tll.show_all_surfaces"}, nil, table_config.show_all_surfaces)
    add_checkbox(constants.actions.toggle_show_satisfied, {"tll.show_satisfied"}, nil, table_config.show_satisfied)
    add_checkbox(constants.actions.toggle_show_not_set, {"tll.show_not_set"}, nil, table_config.show_not_set)
    add_checkbox(constants.actions.toggle_show_dynamic, {"tll.show_dynamic"}, nil, table_config.show_dynamic)
    add_checkbox(constants.actions.toggle_show_single_station_schedules, {"tll.show_single_station_schedules"}, nil, table_config.show_single_station_schedules)
    add_checkbox(constants.actions.toggle_show_train_limits_separately, {"tll.show_train_limits_separately"}, nil, table_config.show_train_limits_separately)
    add_checkbox(constants.actions.toggle_opinionation, {"tll.toggle_opinionation"}, {"tll.toggle_opinionation_tooltip"}, table_config.opinionate)


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