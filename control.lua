local constants = require("constants")
local utils = require("utils")

-- Models
local blueprint_configuration = require("models/blueprint_configuration")
local schedule_table_configuration = require("models/schedule_table_configuration")
local keyword_list = require("models/keyword_list")
local fuel_configuration = require("models.fuel_configuration")
local fuel_category_data = require("models.fuel_category_data")

-- view
local blueprint_orientation_selector = require("views.settings_views.blueprint_orientation_selector")
local blueprint_snap_selection = require("views/settings_views/blueprint_snap_selection")
local slider_textfield = require("views/slider_textfield")
local icon_selector_textfield = require("views/icon_selector_textfield")
local keyword_tables = require("views/keyword_tables")

-- Util functions

---@param id string
---@return LuaTrain
local function get_train_by_id(id)
    for _, surface in pairs(game.surfaces) do
        for _, train in pairs(surface.get_trains()) do
            if train.id == id then return train end
        end
    end
    return nil
end

-- Returns an array of arrays of trains which share a schedule.
---@return table
---     - surface (string): name of a surface
---     - train_schedule_groups LuaTrain[][]: array of arrays of trains, all trains in sub-arrays share a schedule
local function get_train_schedule_groups_by_surface()
    local function train_schedule_to_key(schedule)
        local key
        for _, record in pairs(schedule.records) do
            if not record.temporary and record.station then
                if not key then
                     key = record .station
                else
                    key = key .. " → " .. record.station
                end
            end
        end
        return key
    end

    local surface_train_schedule_groups = {}

    for _, surface in pairs(game.surfaces) do
        local train_schedule_groups = {}
        local added_schedule = false
        for _, train in pairs(surface.get_trains()) do
            local schedule = train.schedule
            if schedule then
                added_schedule = true
                local key = train_schedule_to_key(schedule)
                train_schedule_groups[key] = train_schedule_groups[key] or {}
                table.insert(train_schedule_groups[key], train)
            end
        end
        if added_schedule then
            table.insert(
                surface_train_schedule_groups,
                {
                    surface = surface,
                    train_schedule_groups = train_schedule_groups
                }
            )
        end
    end
    return surface_train_schedule_groups
end

---@param player LuaPlayer
---@param train_schedule_group table: array[LuaTrain]
---@param surface LuaSurface
---@param enabled_excluded_keywords table: array[toggleable_item]
---@return string|number: sum of train limits, or enums defined in constants file to indicate special values
local function get_train_station_limits(player, train_schedule_group, surface, enabled_excluded_keywords)
    local sum_of_limits = 0
    local shared_schedule = train_schedule_group[1].schedule

    for _, record in pairs(shared_schedule.records) do
        local station_is_excluded = false
        for _, enabled_keyword in pairs(enabled_excluded_keywords) do
            local alt_rich_text_format_img = utils.swap_rich_text_format_to_img(enabled_keyword)
            local alt_rich_text_format_entity = utils.swap_rich_text_format_to_entity(enabled_keyword)
            if (string.find(record.station, enabled_keyword, nil, true)
                or string.find(record.station, alt_rich_text_format_img, nil, true)
                or string.find(record.station, alt_rich_text_format_entity, nil, true)
                ) then
                station_is_excluded = true
            end
        end
        if not station_is_excluded then
            for _, train_stop in pairs(surface.get_train_stops({name=record.station})) do
                -- no train limit is implemented as limit == 2 ^ 32 - 1
                if train_stop.trains_limit == (2 ^ 32) - 1 then
                    return constants.train_stop_limit_enums.not_set
                else
                    sum_of_limits = sum_of_limits + train_stop.trains_limit
                end
            end
        end
    end
    return sum_of_limits
end

-- Takes two blueprints. Both have entities 1 thru N_1 and N_2. 
-- Increments each entity's entity_number in the second blueprint by N_1.
---@param entity_list_1 BlueprintEntity[]?
---@param entity_list_2 BlueprintEntity[]?
---@return BlueprintEntity[]
local function combine_blueprint_entities(entity_list_1, entity_list_2)
    local combined = {}
    local increment = entity_list_1 and #entity_list_1 or 0
    if entity_list_1 then for i, entity in pairs(entity_list_1) do
            combined[i] = entity
    end end

    if entity_list_2 then for i, entity in pairs(entity_list_2) do
        combined[i + increment] = entity
    end end
    
    return combined
end

---@param player LuaPlayer
---@return table?
local function get_snap_to_grid(player)
    local config = global.players[player.index].model.blueprint_configuration
    if config.snap_enabled then
        if config.snap_direction == constants.snap_directions.vertical then
            return {x = 100, y = config.snap_width}
        else
            return {x = config.snap_width, y = 100}
        end
    else
        return nil
    end
end

--rotate x and y around the origin by the specified angle (radians)
local function rotate_around_origin(x, y, angle)
    local cosAngle = math.cos(angle)
    local sinAngle = math.sin(angle)

    -- Perform rotation
    local rotatedX = cosAngle * x - sinAngle * y
    local rotatedY = sinAngle * x + cosAngle * y

    return {x = rotatedX, y = rotatedY}
end


---Take a train's entities. Find a locomotive. Rotate all the entities so that the locomotive should point towards the player's currently set orientation. 
---@param entities BlueprintEntity[]
---@return BlueprintEntity[]
local function orient_train_entities(entities, new_orientation)
    local main_orientation
    for _, entity in pairs(entities) do
        if entity.name == "locomotive" then
            main_orientation = entity.orientation
            break
        end
    end
    if not main_orientation then return entities end

    local goal_angle = 2 * math.pi * new_orientation
    local current_angle = main_orientation * 2 * math.pi
    local angle_to_rotate = goal_angle - current_angle

    for _, entity in pairs(entities) do
        entity.position = rotate_around_origin(entity.position.x, entity.position.y, angle_to_rotate)
        if entity.orientation == main_orientation then
            entity.orientation = new_orientation
        else
            entity.orientation = (new_orientation + 0.5) % 1
        end
    end
    
    return entities
end


-- Given a template train, creates a blueprint containing a copy of that train.
-- Can use trains at any angle.
-- First, create a main blueprint.
-- Next, for each carriage in the train, create a blueprint containing only that carriage and set that carriage's position in the blueprint to be 7 higher than the last and set its orientation to be either up or down.
-- Next, combine all those blueprints.
-- Next, add fuel to the trains and add snapping to the blueprint as configured in the model.
---@param player LuaPlayer
---@param train LuaTrain
---@param surface_name string
local function create_blueprint_from_train(player, train, surface_name)

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    local surface = game.get_surface(surface_name)
    if surface == nil then return end
    local script_inventory = game.create_inventory(2)
    local aggregated_blueprint_slot = script_inventory[1]
    aggregated_blueprint_slot.set_stack{name="tll_cursor_blueprint"}
    local single_carriage_slot = script_inventory[2]
    single_carriage_slot.set_stack{name="tll_cursor_blueprint"}

    local prev_vert_offset = 0
    local prev_orientation = nil
    local prev_was_counteraligned = false

    for _, carriage in pairs(train.carriages) do
        single_carriage_slot.create_blueprint{surface=surface, area=carriage.bounding_box, force=player.force, include_trains=true, include_entities=false}
        local new_blueprint_entities = single_carriage_slot.get_blueprint_entities()
        if new_blueprint_entities == nil then return end

        -- vertical offset only works for vanilla rolling stock! should use joint distance and connection distance but these are not visible outside data stage
        local vert_offset = prev_vert_offset + 7
        new_blueprint_entities[1].position = {x=0, y= -1 * vert_offset}

        if prev_orientation == nil then
            prev_orientation = carriage.orientation
            new_blueprint_entities[1].orientation = constants.orientations.d
        else
            local orientation_diff = math.abs(prev_orientation - new_blueprint_entities[1].orientation) % 1
            orientation_diff = math.min(orientation_diff, 1 - orientation_diff)
            if orientation_diff < 0.25 then
                if prev_was_counteraligned then
                    new_blueprint_entities[1].orientation = constants.orientations.u
                else
                    new_blueprint_entities[1].orientation = constants.orientations.d
                end
            else
                if prev_was_counteraligned then
                    new_blueprint_entities[1].orientation = constants.orientations.d
                else
                    new_blueprint_entities[1].orientation = constants.orientations.u
                end
                prev_was_counteraligned = not prev_was_counteraligned
            end
        end
        prev_orientation = carriage.orientation
        prev_vert_offset = vert_offset
        local combined_blueprint_entities = combine_blueprint_entities(new_blueprint_entities, aggregated_blueprint_slot.get_blueprint_entities())
        aggregated_blueprint_slot.set_blueprint_entities(combined_blueprint_entities)
    end

    local aggregated_entities = aggregated_blueprint_slot.get_blueprint_entities()
    for _, entity in pairs(aggregated_entities) do
        local items_to_add = {}
        if player_global.model.fuel_configuration.add_fuel then
            local accepted_fuel_categories = global.model.fuel_category_data.locomotives_fuel_categories[entity.name]
            if accepted_fuel_categories then
                for _, accepted_fuel_category in pairs(accepted_fuel_categories) do
                    local fuel_category_config = player_global.model.fuel_configuration.fuel_category_configurations[accepted_fuel_category]
                    if fuel_category_config.selected_fuel then
                        items_to_add[fuel_category_config.selected_fuel] = fuel_category_config.fuel_amount
                        break
                    end
                end
            end
        end
        entity.items = items_to_add
    end
    aggregated_entities = orient_train_entities(aggregated_entities, player_global.model.blueprint_configuration.new_blueprint_orientation)

    aggregated_blueprint_slot.set_blueprint_entities(aggregated_entities)
    aggregated_blueprint_slot.blueprint_snap_to_grid = get_snap_to_grid(player, aggregated_entities)
    player.add_to_clipboard(aggregated_blueprint_slot)
    player.activate_paste()
    script_inventory.destroy()
end


---@param player LuaPlayer
local function build_train_schedule_group_report(player)

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local surface_train_schedule_groups_pairs = get_train_schedule_groups_by_surface()
    local report_frame = player_global.view.report_frame
    report_frame.clear()

    local enabled_excluded_keywords = player_global.model.excluded_keywords:get_enabled_keywords()
    local enabled_hidden_keywords = player_global.model.hidden_keywords:get_enabled_keywords()

    local table_config = player_global.model.schedule_table_configuration

    local column_count = 4 + (table_config.only_current_surface and 0 or 1)

    local schedule_report_table = report_frame.add{type="table", style="bordered_table", column_count=column_count}
    schedule_report_table.style.maximal_width = 552

    if not table_config.only_current_surface then
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

    for _, surface_train_schedule_groups_pair in pairs(surface_train_schedule_groups_pairs) do
        local surface = surface_train_schedule_groups_pair.surface

        -- barrier for all train schedules for a surface
        if not (table_config.only_current_surface and surface.name ~= player.surface.name) then
            local train_schedule_groups = surface_train_schedule_groups_pair.train_schedule_groups

            local sorted_schedule_names = {}
            for schedule_name, _ in pairs(train_schedule_groups) do table.insert(sorted_schedule_names, schedule_name) end
            table.sort(sorted_schedule_names)

            for _, schedule_name in pairs(sorted_schedule_names) do

                local train_schedule_group = train_schedule_groups[schedule_name]
                local train_limit_sum = get_train_station_limits(player, train_schedule_group, surface, enabled_excluded_keywords)

                local schedule_contains_hidden_keyword = false
                for _, keyword in pairs(enabled_hidden_keywords) do
                    local alt_rich_text_format_img = utils.swap_rich_text_format_to_img(keyword)
                    local alt_rich_text_format_entity = utils.swap_rich_text_format_to_entity(keyword)
                    if (string.find(schedule_name, keyword, nil, true)
                        or string.find(schedule_name, alt_rich_text_format_img, nil, true)
                        or string.find(schedule_name, alt_rich_text_format_entity, nil, true)
                        ) then
                        schedule_contains_hidden_keyword = true
                    end
                end

                local invalid = (train_limit_sum == constants.train_stop_limit_enums.not_set)

                local satisfied
                if type(train_limit_sum) ~= "number" then
                    satisfied = false
                else
                    satisfied = (train_limit_sum - #train_schedule_group == 1)
                end

                -- barrier for showing a particular schedule
                if (
                    (not schedule_contains_hidden_keyword)
                    and (table_config.show_satisfied or (not satisfied))
                    and (table_config.show_invalid or (not invalid))
                ) then

                    local train_limit_sum_caption
                    if train_limit_sum == constants.train_stop_limit_enums.not_set then
                        train_limit_sum_caption = {"tll.train_limit_sum_not_set"}
                    else
                        train_limit_sum_caption = tostring(train_limit_sum)
                    end


                    local train_count_difference -- nil or number
                    if train_limit_sum ~= constants.train_stop_limit_enums.not_set then
                        train_count_difference = train_limit_sum - 1 -  #train_schedule_group
                    end

                    -- caption
                    local train_count_caption = tostring(#train_schedule_group)
                    if train_count_difference and train_count_difference ~= 0 then -- check non-nil
                        local diff_str = train_count_difference > 0 and "+" or ""
                        train_count_caption = train_count_caption .. " (" .. diff_str .. tostring(train_count_difference) .. ") [img=info]"
                    end

                    -- tooltip
                    local recommended_action_tooltip = nil
                    if train_count_difference and train_count_difference ~= 0 then
                        local abs_diff = train_count_difference > 0 and train_count_difference or -1 * train_count_difference
                        recommended_action_tooltip = train_count_difference > 0 and {"tll.add_n_trains_tooltip", abs_diff} or {"tll.remove_n_trains_tooltip", abs_diff}
                    end
                    
                    -- color
                    local train_count_label_color
                    if train_count_difference then
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

                    -- cell 1
                    if not table_config.only_current_surface then
                        schedule_report_table.add{type="label", caption=surface.name}
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
                        tags={action=constants.actions.train_schedule_create_blueprint, template_train_ids=template_train_ids, surface=surface.name},
                        tooltip={"tll.copy_train_blueprint_tooltip"}
                    }
                end
            end
        end
    end
    end

---@return TLLPlayerView
local function get_empty_player_view()
    return {
        fuel_amount_flows={}
    }
end

---@return TLLPlayerGlobal
local function get_default_global()

    local fuel_config = fuel_configuration.TLLFuelConfiguration:new()

    local fuel_categories = global.model.fuel_category_data.fuel_categories_and_fuels

    for fuel_category, _ in pairs(fuel_categories) do
        fuel_config:add_fuel_category_config(fuel_category)
    end

    return {
        model = {
            blueprint_configuration = blueprint_configuration.TLLBlueprintConfiguration:new(),
            schedule_table_configuration = schedule_table_configuration.TLLScheduleTableConfiguration:new(),
            fuel_configuration = fuel_config,
            excluded_keywords = keyword_list.TLLKeywordList:new(),
            hidden_keywords = keyword_list.TLLKeywordList:new(),
            last_gui_location = nil, -- migration not actually necessary, since it starts as nil?
        },
        view = get_empty_player_view()
    }
end

local function initialize_global(player)
    global.players[player.index] = get_default_global()
end

local function migrate_global(player)
    global.players[player.index] = get_default_global()
end

local function build_display_tab(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local display_content_frame = player_global.view.display_content_frame
    if not display_content_frame then return end
    display_content_frame.clear()

    local controls_flow = display_content_frame.add{type="flow", name="controls_flow", direction="vertical", style="tll_controls_flow"}

    local table_config = player_global.model.schedule_table_configuration

    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_current_surface}, caption={"tll.only_player_surface"}, state=table_config.only_current_surface}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_satisfied}, caption={"tll.show_satisfied"}, state=table_config.show_satisfied}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_invalid}, caption={"tll.show_invalid"}, state=table_config.show_invalid}
    local train_report_button = controls_flow.add{type="button", tags={action=constants.actions.train_report_update}, caption={"tll.train_report_button_update"}}
    train_report_button.style.bottom_margin = 10

    local report_frame = display_content_frame.add{type="scroll-pane", name="report_table", direction="vertical"}
    player_global.view.report_frame = report_frame

    build_train_schedule_group_report(player)
end

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
                enabled=fuel_config.add_fuel
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

    build_display_tab(player)

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
        player_global.view = get_empty_player_view()
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
            build_train_schedule_group_report(player)

        elseif action == constants.actions.close_window then
            toggle_interface(player)

        elseif action == constants.actions.exclude_textfield_apply then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.excluded_keywords:set_enabled(text, true)
                keyword_tables.build_excluded_keyword_table(player_global, player_global.model.excluded_keywords)
                build_train_schedule_group_report(player)
            end

        elseif action == constants.actions.delete_excluded_keyword then
            local excluded_keyword = event.element.tags.keyword
            if type(excluded_keyword) ~= "string" then return end
            player_global.model.excluded_keywords:remove_item(excluded_keyword)
            keyword_tables.build_excluded_keyword_table(player_global, player_global.model.excluded_keywords)
            build_train_schedule_group_report(player)

        elseif action == constants.actions.delete_all_excluded_keywords then

            player_global.model.excluded_keywords:remove_all()
            keyword_tables.build_excluded_keyword_table(player_global, player_global.model.excluded_keywords)
            build_train_schedule_group_report(player)

        elseif action == constants.actions.hide_textfield_apply then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.hidden_keywords:set_enabled(text, true)
                keyword_tables.build_hidden_keyword_table(player_global, player_global.model.hidden_keywords)
                build_train_schedule_group_report(player)
            end

        elseif action == constants.actions.delete_hidden_keyword then
            local hidden_keyword = event.element.tags.keyword
            if type(hidden_keyword) ~= "string" then return end
            player_global.model.hidden_keywords:remove_item(hidden_keyword)
            keyword_tables.build_hidden_keyword_table(player_global, player_global.model.hidden_keywords)
            build_train_schedule_group_report(player)

        elseif action == constants.actions.delete_all_hidden_keywords then
            player_global.model.hidden_keywords:remove_all()
            keyword_tables.build_hidden_keyword_table(player_global, player_global.model.hidden_keywords)
            build_train_schedule_group_report(player)

        elseif action == constants.actions.train_schedule_create_blueprint then
            local template_train
            for _, id in pairs(event.element.tags.template_train_ids) do
                local template_option = get_train_by_id(id)
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
            create_blueprint_from_train(player, template_train, surface_name)

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
            build_train_schedule_group_report(player)

        elseif action == constants.actions.toggle_hidden_keyword then
            local keyword = event.element.tags.keyword
            if type(keyword) ~= "string" then return end
            player_global.model.hidden_keywords:toggle_enabled(keyword)
            keyword_tables.build_hidden_keyword_table(player_global, player_global.model.hidden_keywords)
            build_train_schedule_group_report(player)

        elseif action == constants.actions.toggle_current_surface then
            player_global.model.schedule_table_configuration:toggle_current_surface()
            build_train_schedule_group_report(player)

        elseif action == constants.actions.toggle_show_satisfied then
            player_global.model.schedule_table_configuration:toggle_show_satisfied()
            build_train_schedule_group_report(player)

        elseif action == constants.actions.toggle_show_invalid then
            player_global.model.schedule_table_configuration:toggle_show_invalid()
            build_train_schedule_group_report(player)

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
                build_train_schedule_group_report(player)
            end
        elseif action == constants.actions.hide_textfield_apply then
            local text = icon_selector_textfield.get_text_and_reset_textfield(event.element)
            if text ~= "" then -- don't allow user to input the empty string
                player_global.model.hidden_keywords:set_enabled(text, true)
                keyword_tables.build_hidden_keyword_table(player_global, player_global.model.hidden_keywords)
                build_train_schedule_group_report(player)
            end
        end
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    initialize_global(player)
end)

script.on_event(defines.events.on_player_removed, function(event)
    global.players[event.player_index] = nil
end)

script.on_init(function ()

    global.model = {}
    global.model.fuel_category_data = fuel_category_data.get_fuel_category_data()

    local freeplay = remote.interfaces["freeplay"]
    if freeplay then -- TODO: remove this when done with testing
        if freeplay["set_skip_intro"] then remote.call("freeplay", "set_skip_intro", true) end
        if freeplay["set_disable_crashsite"] then remote.call("freeplay", "set_disable_crashsite", true) end
    end
    global.players = {}
    for _, player in pairs(game.players) do
        initialize_global(player)
    end
end)

script.on_configuration_changed(function (config_changed_data)
    if not global.model then global.model = {} end
    global.model.fuel_category_data = fuel_category_data.get_fuel_category_data()

    if config_changed_data.mod_changes["train-limit-linter"] then
        for _, player in pairs(game.players) do
            migrate_global(player)

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
