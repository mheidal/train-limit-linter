local constants = require("constants")
local utils = require("utils")

local schedule_report_table_scripts = require("scripts/schedule_report_table")

local Exports = {}

---@param player LuaPlayer
local function build_train_schedule_group_report(player)

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local report_frame = player_global.view.report_frame
    if not report_frame then return end
    report_frame.clear()

    local enabled_excluded_keywords = player_global.model.excluded_keywords:get_enabled_keywords()
    local enabled_hidden_keywords = player_global.model.hidden_keywords:get_enabled_keywords()

    local table_config = player_global.model.schedule_table_configuration

    local column_count = 4
    column_count = column_count + (table_config.show_all_surfaces and 1 or 0)
    column_count = column_count + (table_config.show_manual and 1 or 0)

    local schedule_report_table = report_frame.add{type="table", style="bordered_table", column_count=column_count}
    schedule_report_table.style.maximal_width = 552

    if table_config.show_all_surfaces then
        schedule_report_table.add{type="label", caption={"tll.surface_header"}}
    end

    local schedule_header_flow = schedule_report_table.add{type="flow", direction="horizontal"}
    schedule_header_flow.add{type="label", caption={"tll.schedule_header"}}
    schedule_header_flow.add{type="empty-widget"}
    schedule_header_flow.style.horizontally_stretchable = true
    schedule_header_flow.style.horizontally_squashable = true
    schedule_header_flow.style.maximal_width = 300

    schedule_report_table.add{type="label", caption={"tll.train_count_header"}}
    schedule_report_table.add{type="label", caption={"tll.sum_of_limits_header"}}
    schedule_report_table.add{type="empty-widget"}

    if table_config.show_manual then
        schedule_report_table.add{type="label", caption={"tll.manual_header"}}
    end

    for surface, train_schedule_groups in pairs(schedule_report_table_scripts.get_train_schedule_groups_by_surface()) do

        -- barrier for all train schedules for a surface
        if table_config.show_all_surfaces or surface == player.surface.name then

            local train_stop_names_to_limits = schedule_report_table_scripts.get_train_station_limits_by_surface(surface)

            local sorted_schedule_names = {}
            for schedule_name, _ in pairs(train_schedule_groups) do table.insert(sorted_schedule_names, schedule_name) end
            table.sort(sorted_schedule_names)

            for _, schedule_name in pairs(sorted_schedule_names) do

                local train_schedule_group = train_schedule_groups[schedule_name]
                local schedule = train_schedule_group[1].schedule

                local train_limit_sum = 0
                local any_train_stop_has_not_set_limit = false
                local schedule_contains_hidden_keyword = false

                for _, station_name in pairs(schedule) do
                    local station_is_excluded = false
                    for _, enabled_keyword in pairs(enabled_excluded_keywords) do
                        local alt_rich_text_format_img = utils.swap_rich_text_format_to_img(enabled_keyword)
                        local alt_rich_text_format_entity = utils.swap_rich_text_format_to_entity(enabled_keyword)
                        if (string.find(station_name, enabled_keyword, nil, true)
                            or string.find(station_name, alt_rich_text_format_img, nil, true)
                            or string.find(station_name, alt_rich_text_format_entity, nil, true)
                            )
                        then
                            station_is_excluded = true
                        end
                    end

                    if not station_is_excluded then
                        if train_stop_names_to_limits[station_name] == constants.train_stop_limit_enums.not_set then
                            any_train_stop_has_not_set_limit = true
                            break
                        else
                            train_limit_sum = train_limit_sum + train_stop_names_to_limits[station_name]
                        end
                    end

                    for _, keyword in pairs(enabled_hidden_keywords) do
                        local alt_rich_text_format_img = utils.swap_rich_text_format_to_img(keyword)
                        local alt_rich_text_format_entity = utils.swap_rich_text_format_to_entity(keyword)
                        if (string.find(station_name, keyword, nil, true)
                            or string.find(station_name, alt_rich_text_format_img, nil, true)
                            or string.find(station_name, alt_rich_text_format_entity, nil, true)
                            )
                        then
                            schedule_contains_hidden_keyword = true
                            break
                        end
                    end
                end

                local satisfied = (not any_train_stop_has_not_set_limit) and (train_limit_sum - #train_schedule_group == 1)

                -- barrier for showing a particular schedule
                if (
                    (not schedule_contains_hidden_keyword)
                    and (table_config.show_satisfied or (not satisfied))
                    and (table_config.show_invalid or (not any_train_stop_has_not_set_limit))
                ) then

                    local train_limit_sum_caption
                    if any_train_stop_has_not_set_limit then
                        train_limit_sum_caption = {"tll.train_limit_sum_not_set"}
                    else
                        train_limit_sum_caption = tostring(train_limit_sum)
                    end

                    local train_count_difference = train_limit_sum - 1 - #train_schedule_group

                    -- caption
                    local train_count_caption = tostring(#train_schedule_group)
                    if train_count_difference ~= 0 and not (any_train_stop_has_not_set_limit) then
                        local diff_str = train_count_difference > 0 and "+" or ""
                        train_count_caption = train_count_caption .. " (" .. diff_str .. tostring(train_count_difference) .. ") [img=info]"
                    end

                    -- tooltip
                    local recommended_action_tooltip = nil
                    if train_count_difference ~= 0 and not (any_train_stop_has_not_set_limit) then
                        local abs_diff = math.abs( train_count_difference)
                        recommended_action_tooltip = train_count_difference > 0 and {"tll.add_n_trains_tooltip", abs_diff} or {"tll.remove_n_trains_tooltip", abs_diff}
                    end

                    -- color
                    local train_count_label_color
                    if not any_train_stop_has_not_set_limit then
                        if train_count_difference ~= 0 then
                            train_count_label_color = {1, 0.541176, 0.541176}
                        else
                            train_count_label_color = {0.375, 0.703125, 0.390625} -- copied from "confirm" buttons in game
                        end
                    else
                        train_count_label_color = {1, 1, 1}
                    end

                    local template_train_ids = {}
                    for _, train_data in pairs(train_schedule_group) do
                        table.insert(template_train_ids, train_data.id)
                    end

                    local manual_train_ids = {}
                    for _, train_data in pairs(train_schedule_group) do
                        if train_data.manual_mode then
                            table.insert(manual_train_ids, train_data.id)
                        end
                    end

                    -- cell 1
                    if table_config.show_all_surfaces then
                        schedule_report_table.add{type="label", caption=surface}
                    end


                    -- cell 2
                    local schedule_cell = schedule_report_table.add{type="flow", direction="horizontal"}
                    local schedule_cell_label = schedule_cell.add{
                        type="label",
                        caption=schedule_name,
                    }
                    schedule_cell_label.style.font_color=train_count_label_color
                    schedule_cell_label.style.horizontally_squashable = true
                    schedule_cell_label.style.horizontally_stretchable = true
                    -- schedule_cell_label.style.minimal_width = 200

                    schedule_cell.add{type="empty-widget"}
                    schedule_cell.style.horizontally_stretchable = true
                    schedule_cell.style.horizontally_squashable = true
                    schedule_cell.style.maximal_width = 300


                    -- cell 3
                    local train_count_cell = schedule_report_table.add{
                        type="label",
                        caption=train_count_caption,
                        tooltip=recommended_action_tooltip
                    }
                    train_count_cell.style.font_color=train_count_label_color

                    -- cell 4
                    schedule_report_table.add{type="label", caption=train_limit_sum_caption}

                    -- cell 5
                    schedule_report_table.add{
                        type="sprite-button",
                        sprite="utility/copy",
                        style="tool_button_blue",
                        tags={action=constants.actions.train_schedule_create_blueprint, template_train_ids=template_train_ids, surface=surface},
                        tooltip={"tll.copy_train_blueprint_tooltip"}
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
                                    surface=surface,
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
end

function Exports.build_display_tab(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local display_content_frame = player_global.view.display_content_frame
    if not display_content_frame then return end

    local controls_flow_name = "controls_flow"
    local controls_flow = display_content_frame[controls_flow_name] or display_content_frame.add{
        type="flow",
        name=controls_flow_name,
        direction="vertical",
        style="tll_controls_flow"
    }
    controls_flow.clear()

    local table_config = player_global.model.schedule_table_configuration

    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_all_surfaces}, caption={"tll.show_all_surfaces"}, state=table_config.show_all_surfaces}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_satisfied}, caption={"tll.show_satisfied"}, state=table_config.show_satisfied}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_invalid}, caption={"tll.show_invalid"}, state=table_config.show_invalid}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_manual}, caption={"tll.show_manual"}, state=table_config.show_manual}

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