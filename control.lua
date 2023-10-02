local constants = require("constants")
local keyword_list = require("models/keyword_list")
local utils = require("utils")

-- Util functions

local function get_table_size(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

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
        for _, train in pairs(surface.get_trains()) do
            local schedule = train.schedule
            if schedule then
                local key = train_schedule_to_key(schedule)
                train_schedule_groups[key] = train_schedule_groups[key] or {}
                table.insert(train_schedule_groups[key], train)
            end
        end
        table.insert(
            surface_train_schedule_groups,
            {
                surface = surface,
                train_schedule_groups = train_schedule_groups
            }
        )
    end
    return surface_train_schedule_groups
end

---@param player LuaPlayer
---@param train_schedule_group table: array[LuaTrain]
---@param surface LuaSurface
---@param enabled_excluded_keywords table: array[toggleable_item]
---@return string|number: sum of train limits, or "not set" if at least one train stop does not have a set limit, or "excluded" if all stops are excluded by keyword
local function get_train_station_limits(player, train_schedule_group, surface, enabled_excluded_keywords)
    local sum_of_limits = 0
    local shared_schedule = train_schedule_group[1].schedule

    for _, record in pairs(shared_schedule.records) do
        for _, enabled_string in pairs(enabled_excluded_keywords) do
            if string.find(record.station, enabled_string) then goto excluded_keyword_in_train_stop_name end -- TODO: crash here!
        end
        for _, train_stop in pairs(surface.get_train_stops({name=record.station})) do
            -- no train limit is implemented as limit == 2 ^ 32 - 1
            if train_stop.trains_limit == (2 ^ 32) - 1 then
                return "not set" -- "not set" used as a sentinal value (how I miss you, Rust)
            else
                sum_of_limits = sum_of_limits + train_stop.trains_limit
            end
        end
        ::excluded_keyword_in_train_stop_name::
    end
    if sum_of_limits == 0 then return "excluded" end
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

---@param orientation number
---@return boolean
local function is_horizontal(orientation)
    local horizontal_orientations = {
        0.25,
        0.75
    }
    return orientation == horizontal_orientations[1] or orientation == horizontal_orientations[2]
end

---@param train LuaTrain
---@return boolean
local function train_is_curved(train)
    local first_orientation
    for _, carriage in pairs(train.carriages) do
        if not first_orientation then first_orientation = carriage.orientation end
        local orientation = carriage.orientation
        if orientation ~= first_orientation and orientation ~= (first_orientation - 0.5) and orientation ~= (first_orientation + 0.5) then
            return true
        end
    end
    return false
end

---@param entities BlueprintEntity[]?
---@return table?
local function get_snap_to_grid_from_blueprint_entities(entities)
    if not entities then return nil end
    if is_horizontal(entities[1].orientation) then
        return {x = 100, y = 4} 
    else
        return {x = 4, y = 100}
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


---Take a train's entities. Find a locomotive. Rotate all the entities so that the locomotive should point downwards. 
---@param entities BlueprintEntity[]
---@return transformed_entities BlueprintEntity[]
local function orient_train_entities_downward(entities)
    local orientation
    for _, entity in pairs(entities) do
        if entity.name == "locomotive" then orientation = entity.orientation end
        break
    end
    if not orientation then return entities end

    local goal_angle = math.pi
    local current_angle = orientation * 2 * math.pi
    local angle_to_rotate = goal_angle - current_angle

    for i, entity in pairs(entities) do
        entity.position = rotate_around_origin(entity.position.x, entity.position.y, angle_to_rotate)
        entity.orientation = 0.5 -- maybe I should make a constants file
    end
    
    return entities
end

---@param player LuaPlayer
---@param train LuaTrain
---@param surface_name string
local function create_blueprint_from_train(player, train, surface_name)
    local player_global = global.players[player.index]

    local surface = game.get_surface(surface_name)
    local script_inventory = game.create_inventory(2)
    local aggregated_blueprint_slot = script_inventory[1]
    aggregated_blueprint_slot.set_stack{name="tll_cursor_blueprint"}
    local single_carriage_slot = script_inventory[2]
    single_carriage_slot.set_stack{name="tll_cursor_blueprint"}

    -- add entities from train
    for _, carriage in pairs(train.carriages) do
        single_carriage_slot.create_blueprint{surface=surface, area=carriage.bounding_box, force=player.force, include_trains=true, include_entities=false}
        local new_blueprint_entities = combine_blueprint_entities(aggregated_blueprint_slot.get_blueprint_entities(), single_carriage_slot.get_blueprint_entities())
        aggregated_blueprint_slot.set_blueprint_entities(new_blueprint_entities)
    end
    local aggregated_entities = aggregated_blueprint_slot.get_blueprint_entities()
    for _, entity in pairs(aggregated_entities) do
        -- change to make more portable across mods?
        if entity.name == "locomotive" then
            if player_global.add_fuel and player_global.selected_fuel then
                entity.items = {}
                entity.items[player_global.selected_fuel] = player_global.fuel_amount
            else
                entity.items = {}
            end
        end
    end
    aggregated_entities = orient_train_entities_downward(aggregated_entities)

    aggregated_blueprint_slot.set_blueprint_entities(aggregated_entities)
    aggregated_blueprint_slot.blueprint_snap_to_grid = get_snap_to_grid_from_blueprint_entities(aggregated_entities)
    player.add_to_clipboard(aggregated_blueprint_slot)
    player.activate_paste()
    script_inventory.destroy()
end


---@param player LuaPlayer
local function build_train_schedule_group_report(player)
    local player_global = global.players[player.index]
    local surface_train_schedule_groups_pairs = get_train_schedule_groups_by_surface()
    local report_frame = player_global.elements.report_frame
    report_frame.clear()

    local enabled_excluded_keywords = unique_toggleable_list.get_enabled_strings(player_global.excluded_keywords.toggleable_items)

    for _, surface_train_schedule_groups_pair in pairs(surface_train_schedule_groups_pairs) do
        local surface = surface_train_schedule_groups_pair.surface
        if player_global.only_current_surface and surface.name ~= player.surface.name then goto ignore_surface end

        local train_schedule_groups = surface_train_schedule_groups_pair.train_schedule_groups
        local num_train_schedule_groups = get_table_size(train_schedule_groups)
        if num_train_schedule_groups == 0 then
            goto ignore_surface
        end
        local surface_label = nil
        if not player_global.only_current_surface then
            -- caption added at end of surface loop
            surface_label = report_frame.add{type="label", name="surface_label_" .. surface.name, ignored_by_interaction=true}
            surface_label.style.horizontally_stretchable = true
            surface_label.style.margin = 5
        end

        local surface_pane = report_frame.add{type="scroll-pane", name="report_table_" .. surface.name , style="rb_list_box_scroll_pane"}

        local num_valid_train_schedule_groups = 0 -- "valid" here meaning that they're shown

        for key, train_schedule_group in pairs(train_schedule_groups) do
            for _, enabled_hidden_keyword in pairs(unique_toggleable_list.get_enabled_strings(player_global.hidden_keywords.toggleable_items)) do
                if string.find(key, enabled_hidden_keyword) then goto schedule_excluded end
            end
            local train_limit_sum = get_train_station_limits(player, train_schedule_group, surface, enabled_excluded_keywords)
            if train_limit_sum == "excluded" then goto schedule_excluded end

            local invalid = (train_limit_sum == "not set")
            local satisfied = not invalid and (train_limit_sum - #train_schedule_group == 1)

            if (
                (player_global.show_satisfied and satisfied)
                or (player_global.show_invalid and invalid)
                or (not invalid and not satisfied)
                ) then
                    num_valid_train_schedule_groups = num_valid_train_schedule_groups + 1
                    local caption = tostring(#train_schedule_group) .. "/" .. tostring(train_limit_sum) .. " --- " .. key
                    local template_train_ids = {}
                    for _, train in pairs(train_schedule_group) do
                        table.insert(template_train_ids, train.id)
                    end
                    surface_pane.add{
                        type="button",
                        style="rb_list_box_item",
                        tags={
                            action=constants.actions.train_schedule_create_blueprint,
                            template_train_ids=template_train_ids,
                            surface=surface.name
                        },
                        caption=caption
                    }
            end
            ::schedule_excluded::
        end

        -- kinda hacky, if you didn't end up adding any of the schedules because it didn't meet any conditions then we don't want to add the label or table for the surface
        if num_valid_train_schedule_groups == 0 then
            if surface_label then surface_label.destroy() end
            surface_pane.destroy()
            goto ignore_surface
        end

        if surface_label then
            local surface_label_caption = surface.name .. ": " .. tostring(num_valid_train_schedule_groups) .. " train schedule" .. (num_valid_train_schedule_groups == 1 and "" or "s")
            report_frame["surface_label_" .. surface.name].caption=surface_label_caption
        end

    ::ignore_surface::
    end
end

local function build_keyword_table(player, keywords, parent, toggle_keyword_enabled_tag, delete_action_tag)
    if get_table_size(keywords) == 0 then
        parent.add{type="label", caption={"tll.no_keywords"}}
        return
    end
    for keyword, string_data in pairs(keywords.toggleable_items) do
        local excluded_keyword_line = parent.add{type="flow", direction="horizontal"}
        excluded_keyword_line.add{type="checkbox", state=string_data.enabled, tags={action=toggle_keyword_enabled_tag, keyword=keyword}}
        excluded_keyword_line.add{type="label", caption=keyword}
        local spacer = excluded_keyword_line.add{type="empty-widget"}
        spacer.style.horizontally_stretchable = true
        excluded_keyword_line.add{type="sprite-button", tags={action=delete_action_tag, keyword=keyword}, sprite="utility/trash", style="tool_button_red"}
    end
end

local function build_excluded_keyword_table(player)
    local player_global = global.players[player.index]
    local excluded_keywords_frame = player_global.elements.excluded_keywords_frame
    excluded_keywords_frame.clear()
    build_keyword_table(player, player_global.excluded_keywords, excluded_keywords_frame, constants.actions.toggle_excluded_keyword, "delete_excluded_keyword")
end

local function build_hidden_keyword_table(player)
    local player_global = global.players[player.index]
    local hidden_keywords_frame = player_global.elements.hidden_keywords_frame
    hidden_keywords_frame.clear()
    build_keyword_table(player, player_global.hidden_keywords, hidden_keywords_frame, "toggle_hidden_keyword", constants.actions.delete_hidden_keyword)
end

local function initialize_global(player)
    global.players[player.index] = {
        only_current_surface = true,
        show_satisfied = true, -- satisfied when sum of train limits is 1 greater than sum of trains
        show_invalid = false, -- invalid when train limits are not set for all stations in name group
        add_fuel = true, -- boolean
        selected_fuel = nil, -- nil or string
        fuel_amount = 0, -- 0 to 3 stacks of selected_fuel
        excluded_keywords = utils.deepCopy(keyword_list.unique_toggleable_list),
        hidden_keywords = utils.deepCopy(keyword_list.unique_toggleable_list),
        elements = {}
    }
end

local function build_display_tab(player)
    local player_global = global.players[player.index]
    local display_content_frame = player_global.elements.display_content_frame
    display_content_frame.clear()

    local controls_flow = display_content_frame.add{type="flow", name="controls_flow", direction="vertical", style="ugg_controls_flow"}

    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_current_surface}, caption={"tll.only_player_surface"}, state=player_global.only_current_surface}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_satisfied}, caption={"tll.show_satisfied"}, state=player_global.show_satisfied}
    controls_flow.add{type="checkbox", tags={action=constants.actions.toggle_show_invalid}, caption={"tll.show_invalid"}, state=player_global.show_invalid}
    local train_report_button = controls_flow.add{type="button", tags={action=constants.actions.train_report_update}, caption={"tll.train_report_button_update"}}
    train_report_button.style.bottom_margin = 10

    local report_frame = display_content_frame.add{type="scroll-pane", name="report_table", direction="vertical"}
    report_frame.style.horizontally_stretchable = true
    player_global.elements.report_frame = report_frame

    build_train_schedule_group_report(player)
end

local function build_exclude_tab(player)
    local player_global = global.players[player.index]
    local exclude_content_frame = player_global.elements.exclude_content_frame
    exclude_content_frame.clear()

    local exclude_control_flow = exclude_content_frame.add{type="flow", direction="vertical", style="ugg_controls_flow"}
    exclude_control_flow.style.bottom_margin = 5
    exclude_control_flow.add{type="label", caption={"tll.add_excluded_keyword"}, tooltip={"tll.add_excluded_keyword_tooltip"}}
    local exclude_textfield_flow = exclude_control_flow.add{type="flow", direction="horizontal"}
    local exclude_entry_textfield = exclude_textfield_flow.add{type="textfield"}
    player_global.elements.exclude_entry_textfield = exclude_entry_textfield
    exclude_textfield_flow.add{type="sprite-button", tags={action=constants.actions.exclude_textfield_apply}, style="item_and_count_select_confirm", sprite="utility/enter", tooltip={"tll.apply_change"}}
    local spacer = exclude_textfield_flow.add{type="empty-widget"}
    spacer.style.horizontally_stretchable = true
    exclude_textfield_flow.add{type="sprite-button", tags={action=constants.actions.delete_all_excluded_keywords}, style="tool_button_red", sprite="utility/trash", tooltip={"tll.delete_all_keywords"}}


    local excluded_keywords_frame = exclude_content_frame.add{type="scroll-pane", direction="vertical"}
    player_global.elements.excluded_keywords_frame = excluded_keywords_frame

    build_excluded_keyword_table(player)

end

-- TODO: merge a lot of this logic with exclude? building of apply textfield, at least?
local function build_hide_tab(player)
    local player_global = global.players[player.index]
    local hide_content_frame = player_global.elements.hide_content_frame
    hide_content_frame.clear()
    local control_flow = hide_content_frame.add{type="flow", direction="vertical", style="ugg_controls_flow"}
    control_flow.style.bottom_margin = 5
    control_flow.add{type="label", caption={"tll.add_hidden_keyword"}, tooltip={"tll.add_hidden_keyword_tooltip"}}
    local textfield_flow = control_flow.add{type="flow", direction="horizontal"}
    local entry_textfield = textfield_flow.add{type="textfield"}
    player_global.elements.hide_entry_textfield = entry_textfield
    textfield_flow.add{type="sprite-button", tags={action=constants.actions.hide_textfield_apply}, style="item_and_count_select_confirm", sprite="utility/enter", tooltip={"tll.apply_change"}}
    local spacer = textfield_flow.add{type="empty-widget"}
    spacer.style.horizontally_stretchable = true
    textfield_flow.add{type="sprite-button", tags={action=constants.actions.delete_all_hidden_keywords}, style="tool_button_red", sprite="utility/trash", tooltip={"tll.delete_all_keywords"}}

    local hidden_keywords_frame = hide_content_frame.add{type="scroll-pane", direction="vertical"}
    player_global.elements.hidden_keywords_frame = hidden_keywords_frame

    build_hidden_keyword_table(player)

end

local function build_fuel_tab(player)
    local player_global = global.players[player.index]
    local fuel_content_frame = player_global.elements.fuel_content_frame
    fuel_content_frame.clear()

    fuel_content_frame.add{type="label", caption={"tll.fuel_selector"}}
    fuel_content_frame.add{type="checkbox", tags={action=constants.actions.toggle_place_trains_with_fuel}, state=player_global.add_fuel, caption={"tll.place_trains_with_fuel_checkbox"}}

    local fuel_amount_frame_enabled = player_global.add_fuel and player_global.selected_fuel ~= nil
    local maximum_fuel_amount = (fuel_amount_frame_enabled and (game.item_prototypes[player_global.selected_fuel].stack_size * 3)) or 1

    local capped_fuel_amount = player_global.fuel_amount >= maximum_fuel_amount and maximum_fuel_amount or player_global.fuel_amount

    local fuel_amount_frame = fuel_content_frame.add{type="frame", direction="horizontal"}
    fuel_amount_frame.style.top_margin = 10
    fuel_amount_frame.style.bottom_margin = 10
    local fuel_amount_textfield = fuel_amount_frame.add{type="textfield", tags={action=constants.actions.update_fuel_amount_textfield}, text=tostring(capped_fuel_amount), numeric=true, allow_decimal=false, allow_negative=false, enabled=fuel_amount_frame_enabled}
    local fuel_amount_slider = fuel_amount_frame.add{type="slider", tags={action=constants.actions.update_fuel_amount_slider}, value=capped_fuel_amount, minimum_value=0, maximum_value=maximum_fuel_amount, style="notched_slider", enabled=fuel_amount_frame_enabled}

    player_global.elements.fuel_amount_textfield = fuel_amount_textfield
    player_global.elements.fuel_amount_slider = fuel_amount_slider

    local valid_fuels = {}
    for i, prototype in pairs(game.item_prototypes) do
        if prototype.fuel_category and prototype.fuel_category == "chemical" then
            table.insert(valid_fuels, prototype)
        end
    end

    local fuel_button_table = fuel_content_frame.add{type="table", column_count=#valid_fuels <= 10 and #valid_fuels or 10, style="filter_slot_table"}

    for _, fuel in pairs(valid_fuels) do
        local item_name = fuel.name
        local button_style = (item_name == player_global.selected_fuel) and "yellow_slot_button" or "recipe_slot_button"
        fuel_button_table.add{type="sprite-button", sprite=("item/" .. item_name), tags={action=constants.actions.select_fuel, item_name=item_name}, style=button_style, enabled = player_global.add_fuel} -- TODO: select on click
    end
end

local function build_interface(player)
    local player_global = global.players[player.index]

    local screen_element = player.gui.screen

    local main_frame = screen_element.add{type="frame", name="tll_main_frame", direction="vertical"}
    main_frame.style.size = {480, 300}
    main_frame.style.minimal_height = 300
    main_frame.style.maximal_height = 810
    main_frame.style.vertically_stretchable = true

    main_frame.auto_center = true

    player.opened = main_frame
    player_global.elements.main_frame = main_frame

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
    local display_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="ugg_content_frame"}
    tabbed_pane.add_tab(display_tab, display_content_frame)

    player_global.elements.display_content_frame = display_content_frame

    build_display_tab(player)

    -- exclude tab
    local exclude_tab = tabbed_pane.add{type="tab", caption={"tll.exclude_tab"}}
    local exclude_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="ugg_content_frame"}
    tabbed_pane.add_tab(exclude_tab, exclude_content_frame)
    player_global.elements.exclude_content_frame = exclude_content_frame

    build_exclude_tab(player)

    -- hide tab
    local hide_tab = tabbed_pane.add{type="tab", caption={"tll.hide_tab"}}
    local hide_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="ugg_content_frame"}
    tabbed_pane.add_tab(hide_tab, hide_content_frame)
    player_global.elements.hide_content_frame = hide_content_frame

    build_hide_tab(player)

    -- fuel tab

    local fuel_tab = tabbed_pane.add{type="tab", caption={"tll.fuel_tab"}}
    local fuel_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="ugg_content_frame"}
    tabbed_pane.add_tab(fuel_tab, fuel_content_frame)

    player_global.elements.fuel_content_frame = fuel_content_frame

    build_fuel_tab(player)

end

local function toggle_interface(player)
    local player_global = global.players[player.index]
    local main_frame = player_global.elements.main_frame
    if main_frame == nil then
        player.opened = player_global.elements.main_frame
        build_interface(player)
    else
        main_frame.destroy()
        player_global.elements = {}
    end
end

script.on_event("tll_toggle_interface", function(event)
    local player = game.get_player(event.player_index)
    toggle_interface(player)
end)

script.on_event(defines.events.on_gui_click, function (event)
    local player = game.get_player(event.player_index)
    if not player then return end -- assure vscode that player is not nil
    local player_global = global.players[player.index]
    if event.element.tags.action then
        local action = event.element.tags.action
         if action == constants.actions.select_fuel then
            local item_name =  event.element.tags.item_name
            if player_global.selected_fuel == item_name then
                player_global.selected_fuel = nil
            else
                player_global.selected_fuel = item_name
            end
            build_fuel_tab(player)
            return

        elseif action == constants.actions.train_report_update then
            build_train_schedule_group_report(player)

        elseif action == constants.actions.close_window then
            toggle_interface(player)

        elseif action == constants.actions.exclude_textfield_apply then
            local text = player_global.elements.exclude_entry_textfield.text
            if text ~= "" then -- don't allow user to input the empty string
                keyword_list.set_enabled(player_global.excluded_keywords, text, true)
                player_global.elements.exclude_entry_textfield.text = ""
                build_excluded_keyword_table(player)
                build_train_schedule_group_report(player)
            end

        elseif action == constants.actions.delete_excluded_keyword then
            local excluded_keyword = event.element.tags.keyword
            player_global.excluded_keywords.toggleable_items[excluded_keyword] = nil
            build_excluded_keyword_table(player)
            build_train_schedule_group_report(player)

        elseif action == constants.actions.delete_all_excluded_keywords then
            player_global.excluded_keywords = deepCopy(keyword_list.unique_toggleable_list)
            build_excluded_keyword_table(player)
            build_train_schedule_group_report(player)

        elseif action == constants.actions.hide_textfield_apply then
            local text = player_global.elements.hide_entry_textfield.text
            if text ~= "" then -- don't allow user to input the empty string
                keyword_list.set_enabled(player_global.hidden_keywords, text, true)
                player_global.elements.hide_entry_textfield.text = ""
                build_hidden_keyword_table(player)
                build_train_schedule_group_report(player)
            end

        elseif action == constants.actions.delete_hidden_keyword then
            player_global.excluded_keywords.toggleable_items[event.element.tags.keyword] = nil
            build_hidden_keyword_table(player)
            build_train_schedule_group_report(player)

        elseif action == constants.delete_all_hidden_keywords then
            player_global.hidden_keywords = deepCopy(keyword_list.unique_toggleable_list)
            build_hidden_keyword_table(player)
            build_train_schedule_group_report(player)

        elseif action == constants.actions.train_schedule_create_blueprint then
            local template_train
            for _, id in pairs(event.element.tags.template_train_ids) do
                local template_option = get_train_by_id(id)
                if template_option and not train_is_curved(template_option) then
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
        end
    end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
    local player = game.get_player(event.player_index)
    if not player then return end -- assure vscode that player is not nil
    local player_global = global.players[player.index]
    if event.element.tags.action then
        local action = event.element.tags.action
        if action == constants.actions.toggle_excluded_keyword then
            local keyword = event.element.tags.keyword
            player_global.excluded_keywords.toggleable_items[keyword].enabled = not player_global.excluded_keywords.toggleable_items[keyword].enabled
            build_excluded_keyword_table(player)
            build_train_schedule_group_report(player)
        elseif action == "toggle_hidden_keyword" then

        elseif action == constants.actions.toggle_current_surface then
            player_global.only_current_surface = not player_global.only_current_surface
            build_train_schedule_group_report(player)

        elseif action == constants.actions.toggle_show_satisfied then
            player_global.show_satisfied = not player_global.show_satisfied
            build_train_schedule_group_report(player)
        elseif action == constants.actions.toggle_show_invalid then
            player_global.show_invalid = not player_global.show_invalid
            build_train_schedule_group_report(player)

        elseif action == constants.actions.toggle_place_trains_with_fuel then
            player_global.add_fuel = not player_global.add_fuel
            build_fuel_tab(player)
        end
    end
end)

script.on_event(defines.events.on_gui_value_changed, function (event)
    local player = game.get_player(event.player_index)
    local player_global = global.players[player.index]
    if event.element.tags.action then
        if event.element.tags.action == constants.actions.update_fuel_amount_slider then
            local new_fuel_amount = event.element.slider_value
            player_global.fuel_amount = new_fuel_amount
            player_global.elements.fuel_amount_textfield.text = tostring(new_fuel_amount)
        end
    end
end)

script.on_event(defines.events.on_gui_text_changed, function (event)
    local player = game.get_player(event.player_index)
    local player_global = global.players[player.index]
    if event.element.tags.action then
        if event.element.tags.action == constants.actions.update_fuel_amount_textfield then
            local new_fuel_amount = tonumber(event.element.text)
            local maximum_fuel_amount = game.item_prototypes[player_global.selected_fuel].stack_size * 3
            new_fuel_amount = new_fuel_amount <= maximum_fuel_amount and new_fuel_amount or maximum_fuel_amount
            player_global.fuel_amount = new_fuel_amount
            player_global.elements.fuel_amount_slider.slider_value = new_fuel_amount
        end
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    if event.element and event.element.name == "tll_main_frame" then
        local player = game.get_player(event.player_index)
        toggle_interface(player)
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
    if config_changed_data.mod_changes["train-limit-linter"] or true then
        for _, player in pairs(game.players) do
            initialize_global(player)
            local player_global = global.players[player.index]
            if player_global.elements.main_frame ~= nil then
                toggle_interface(player)
            else
                player.opened = nil
            end
        end
    end
end)
