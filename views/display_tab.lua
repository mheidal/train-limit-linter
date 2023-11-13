local constants = require("constants")
local utils = require("utils")

local schedule_report_table_scripts = require("scripts.schedule_report_table")

local collapsible_frame = require("views.collapsible_frame")

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


    for _, surface_train_schedule_groups_pair in pairs(surface_train_schedule_groups_pairs) do
        local surface = surface_train_schedule_groups_pair.surface

        -- barrier for all train schedules for a surface
        if table_config.show_all_surfaces or surface.name == player.surface.name then
            local train_schedule_groups = surface_train_schedule_groups_pair.train_schedule_groups

            local sorted_schedule_names = {}
            for schedule_name, _ in pairs(train_schedule_groups) do table.insert(sorted_schedule_names, schedule_name) end
            table.sort(sorted_schedule_names)

            for _, schedule_name in pairs(sorted_schedule_names) do
                ---@type LuaTrain[]
                local train_schedule_group = train_schedule_groups[schedule_name]
                local schedule_report_data = schedule_report_table_scripts.get_train_stop_data(train_schedule_group, surface, enabled_excluded_keywords, enabled_hidden_keywords, rails_under_trains_without_schedules)

                local single_station_schedule = #train_schedule_group[1].schedule.records == 1


                local nonexistent_stations_in_schedule = {}
                local any_nonexistent_stations_in_schedule = false
                for _, record in pairs(train_schedule_group[1].schedule.records) do
                    if not schedule_report_data.train_stops[record.station] then
                        nonexistent_stations_in_schedule[record.station] = true
                        any_nonexistent_stations_in_schedule = true
                    end
                end

                local satisfied = (
                    (not (
                        schedule_report_data.dynamic
                        or schedule_report_data.not_set
                        or single_station_schedule
                        or any_nonexistent_stations_in_schedule
                    ))
                    and (schedule_report_data.limit - #train_schedule_group == 1)
                )

                -- barrier for showing a particular schedule
                if (
                    (not schedule_report_data.hidden)
                    and (table_config.show_satisfied or (not satisfied))
                    and (table_config.show_not_set or (not schedule_report_data.not_set))
                    and (table_config.show_dynamic or (not schedule_report_data.dynamic))
                    and (table_config.show_single_station_schedules or (not single_station_schedule))
                ) then
                    any_schedule_shown = true

                    -- schedule caption
                    local schedule_caption = ""
                    for _, record in pairs(train_schedule_group[1].schedule.records) do
                        if schedule_caption == "" then
                            schedule_caption = record.station
                        else
                            schedule_caption = schedule_caption .. " → " .. record.station
                        end
                        if table_config.show_train_limits_separately then
                            local train_group_limit = 0
                            if schedule_report_data.train_stops[record.station] then
                                for _, train_stop_data in pairs(schedule_report_data.train_stops[record.station]) do
                                    train_group_limit = train_group_limit + train_stop_data.limit
                                end
                            end
                            schedule_caption = schedule_caption .. " (" .. train_group_limit .. ")"
                        end
                        if nonexistent_stations_in_schedule[record.station] then
                            schedule_caption = schedule_caption .. " [img=utility/warning_icon]"
                        end
                    end

                    local schedule_caption_tooltip = utils.deep_copy(schedule_caption)
                    for station, _ in pairs(nonexistent_stations_in_schedule) do
                        schedule_caption_tooltip = {"", schedule_caption_tooltip, {"tll.no_stations_with_name", station}}
                    end

                    local train_limit_sum_caption = {
                        "",
                        tostring(schedule_report_data.limit),
                        (schedule_report_data.not_set or schedule_report_data.dynamic) and {"tll.warning_icon"} or "",
                    }
                    local train_limit_sum_tooltip = {
                        "",
                        schedule_report_data.not_set and {"tll.train_limit_not_set_tooltip"} or "",
                        schedule_report_data.not_set and schedule_report_data.dynamic and "\n" or "",
                        schedule_report_data.dynamic and {"tll.train_limit_dynamic_tooltip"} or "",
                    }

                    local show_opinionation = (
                        player_global.model.general_configuration.opinionate
                        or (
                                not schedule_report_data.not_set
                                and not schedule_report_data.dynamic
                                and not single_station_schedule
                                and not any_nonexistent_stations_in_schedule
                        )
                    )

                    local train_count_difference = schedule_report_data.limit - 1 - #train_schedule_group

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
                        parked_train_positions=any_trains_with_no_schedule_parked and parked_train_positions_and_train_stops or nil,
                        template_train_stops=template_train_stops
                    }


                    schedule_report_table.add{
                        type="sprite-button",
                        sprite=copy_sprite,
                        style="tool_button_blue",
                        tags=copy_tags,
                        tooltip=copy_tooltip,
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

    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_all_surfaces}, caption={"tll.show_all_surfaces"}, state=table_config.show_all_surfaces}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_satisfied}, caption={"tll.show_satisfied"}, state=table_config.show_satisfied}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_not_set}, caption={"tll.show_not_set"}, state=table_config.show_not_set}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_dynamic}, caption={"tll.show_dynamic"}, state=table_config.show_dynamic}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_single_station_schedules}, caption={"tll.show_single_station_schedules"}, state=table_config.show_single_station_schedules}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_train_limits_separately}, caption={"tll.show_train_limits_separately"}, state=table_config.show_train_limits_separately}

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