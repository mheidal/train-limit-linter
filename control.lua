-- Util functions

local function get_table_size(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

local function contains(t, k)
    for key, value in pairs(t) do
        if key == k then return true end
    end
    return false
end

local function get_enabled_excluded_strings(player)
    local player_global = global.players[player.index]
    local enabled_excluded_strings = {}
    for string, string_data in pairs(player_global.excluded_strings) do
        if string_data.enabled then table.insert(enabled_excluded_strings, string) end
    end
    return enabled_excluded_strings
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
        local key = ""
        for _, record in pairs(schedule.records) do
            if not record.temporary and record.station then
                key = key .. " " .. record.station
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
---@param enabled_excluded_strings table: array[string]
---@return string|number: sum of train limits, or "not set" if at least one train stop does not have a set limit, or "excluded" if all stops are excluded by keyword
local function get_train_station_limits(player, train_schedule_group, surface, enabled_excluded_strings)
    local sum_of_limits = 0
    local shared_schedule = train_schedule_group[1].schedule

    for _, record in pairs(shared_schedule.records) do
        for _, excluded_string in pairs(enabled_excluded_strings) do
            if string.find(record.station, excluded_string) then goto excluded_string_in_train_stop_name end
        end
        for _, train_stop in pairs(surface.get_train_stops({name=record.station})) do
            -- no train limit is implemented as limit == 2 ^ 32 - 1
            if train_stop.trains_limit == (2 ^ 32) - 1 then
                return "not set" -- "not set" used as a sentinal value (how I miss you, Rust)
            else
                sum_of_limits = sum_of_limits + train_stop.trains_limit
            end
        end
        ::excluded_string_in_train_stop_name::
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

---@param orientation number
---@return boolean
local function is_vertical(orientation)
    local vertical_orientations = {
        0,
        0.5
    }

    return orientation == vertical_orientations[1] or orientation == vertical_orientations[2]
end

---comment
---@param entities BlueprintEntity[]?
---@return table?
local function get_snap_to_grid_from_blueprint_entities(entities)

    local y_snap
    local x_snap

    if not entities then return nil end
    if is_horizontal(entities[1].orientation) then
        x_snap = 100
        y_snap = 4
    else
        x_snap = 4
        y_snap = 100
    end

    return {
        x = x_snap,
        y = y_snap
    } -- key should be "blueprint_snap_to_grid"
end

---@param player LuaPlayer
---@param train LuaTrain
---@param surface_name string
local function create_blueprint_from_train(player, train, surface_name)
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

    local enabled_excluded_strings = get_enabled_excluded_strings(player)

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
            local train_limit_sum = get_train_station_limits(player, train_schedule_group, surface, enabled_excluded_strings)
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
                            train_schedule_create_blueprint_button=true,
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

local function build_excluded_string_table(player)
    local player_global = global.players[player.index]
    local excluded_strings_frame = player_global.elements.excluded_strings_frame
    excluded_strings_frame.clear()
    if get_table_size(player_global.excluded_strings) == 0 then
        excluded_strings_frame.add{type="label", caption={"tll.no_excluded_strings"}}
        return
    end
    for excluded_string, string_data in pairs(player_global.excluded_strings) do
        local excluded_string_line = excluded_strings_frame.add{type="flow", direction="horizontal"}
        excluded_string_line.add{type="checkbox", state=string_data.enabled, tags={associated_string=excluded_string}}
        excluded_string_line.add{type="label", caption=excluded_string}
        local spacer = excluded_string_line.add{type="empty-widget"}
        spacer.style.horizontally_stretchable = true
        excluded_string_line.add{type="sprite-button", name="delete_excluded_string_button", sprite="utility/trash", style="tool_button_red", tags={associated_string=excluded_string}}
    end

end


local function initialize_global(player)
    global.players[player.index] = {
        only_current_surface = true,
        show_satisfied = true, -- satisfied when sum of train limits is 1 greater than sum of trains
        show_invalid = false, -- invalid when train limits are not set for all stations in name group
        add_fuel = true,
        selected_fuel = nil,
        excluded_strings = {}, -- table of tables with structure {<excluded string>={"enabled": bool}}
        elements = {}
    }
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

    titlebar_flow.add{type="sprite-button", name="close_window_button", style="frame_action_button", sprite = "utility/close_white", tooltip={"tll.close"}}

    -- tabs
    local tab_pane_frame = main_frame.add{type="frame", style="inside_deep_frame_for_tabs"}
    local tabbed_pane = tab_pane_frame.add{type="tabbed-pane", style="tabbed_pane_with_no_side_padding"}

    -- display tab
    local display_tab = tabbed_pane.add{type="tab", caption={"tll.display_tab"}}
    local display_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="ugg_content_frame"}
    tabbed_pane.add_tab(display_tab, display_content_frame)

    local controls_flow = display_content_frame.add{type="flow", name="controls_flow", direction="vertical", style="ugg_controls_flow"}

    controls_flow.add{type="checkbox", name="current_surface_checkbox", caption={"tll.only_player_surface"}, state=player_global.only_current_surface}
    controls_flow.add{type="checkbox", name="show_satisfied_checkbox", caption={"tll.show_satisfied"}, state=player_global.show_satisfied}
    controls_flow.add{type="checkbox", name="show_invalid_checkbox", caption={"tll.show_invalid"}, state=player_global.show_invalid}
    local train_report_button = controls_flow.add{type="button", name="train_report_button", caption={"tll.train_report_button_update"}}
    train_report_button.style.bottom_margin = 10

    local report_frame = display_content_frame.add{type="scroll-pane", name="report_table", direction="vertical"}
    report_frame.style.horizontally_stretchable = true
    player_global.elements.report_frame = report_frame

    build_train_schedule_group_report(player)

    -- exclude tab
    local exclude_tab = tabbed_pane.add{type="tab", caption={"tll.exclude_tab"}}
    local exclude_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="ugg_content_frame"}
    tabbed_pane.add_tab(exclude_tab, exclude_content_frame)

    local exclude_control_flow = exclude_content_frame.add{type="flow", direction="vertical", style="ugg_controls_flow"}
    exclude_control_flow.style.bottom_margin = 5
    exclude_control_flow.add{type="label", caption={"tll.add_excluded_keyword"}, tooltip={"tll.add_excluded_keyword_tooltip"}}
    local exclude_textfield_flow = exclude_control_flow.add{type="flow", direction="horizontal"}
    local exclude_entry_textfield = exclude_textfield_flow.add{type="textfield"}
    player_global.elements.exclude_entry_textfield = exclude_entry_textfield
    exclude_textfield_flow.add{type="sprite-button", name="exclude_textfield_apply", style="item_and_count_select_confirm", sprite="utility/enter", tooltip={"tll.apply_change"}}
    local spacer = exclude_textfield_flow.add{type="empty-widget"}
    spacer.style.horizontally_stretchable = true
    exclude_textfield_flow.add{type="sprite-button", name="delete_all_excluded_strings_button", style="tool_button_red", sprite="utility/trash", tooltip={"tll.delete_all_excluded"}}


    local excluded_strings_frame = exclude_content_frame.add{type="scroll-pane", direction="vertical"}
    player_global.elements.excluded_strings_frame = excluded_strings_frame

    build_excluded_string_table(player)

    -- fuel tab

    player_global.add_fuel = true
    player_global.selected_fuel = nil

    local fuel_tab = tabbed_pane.add{type="tab", caption={"tll.fuel_tab"}}
    local fuel_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="ugg_content_frame"}
    tabbed_pane.add_tab(fuel_tab, fuel_content_frame)
    -- TODO: fuel selector
    fuel_content_frame.add{type="label", caption={"tll.fuel_selector"}}
    fuel_content_frame.add{type="checkbox", state=player_global.add_fuel, caption={"tll.place_trains_with_fuel_checkbox"}}

    local valid_fuels = {}
    for _, prototype in pairs(game.item_prototypes) do
        if prototype.fuel_category and prototype.fuel_category == "chemical" then
            table.insert(valid_fuels, prototype)
        end
    end

    local fuel_button_table = fuel_content_frame.add{type="table", column_count=#valid_fuels <= 10 and #valid_fuels or 10, style="filter_slot_table"}

    for _, fuel in pairs(valid_fuels) do
        local item_name = fuel.name
        local button_style = (item_name == player_global.selected_fuel) and "yellow_slot_button" or "recipe_slot_button"
        fuel_button_table.add{type="sprite-button", sprite=("item/" .. item_name), tags={}, style=button_style} -- TODO: select on click
    end

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
    if event.element.name == "train_report_button" then
        event.element.caption = {"tll.train_report_button_update"}
        build_train_schedule_group_report(player)
    elseif event.element.name == "close_window_button" then
        toggle_interface(player)
    elseif event.element.name == "exclude_textfield_apply" then
        local text = player_global.elements.exclude_entry_textfield.text
        if text ~= "" then -- don't allow user to input the empty string
            player_global.excluded_strings[text] = {enabled=true}
            player_global.elements.exclude_entry_textfield.text = ""
            build_excluded_string_table(player)
            build_train_schedule_group_report(player)
        end
    elseif event.element.name == "delete_excluded_string_button" then
        local excluded_string = event.element.tags.associated_string
        player_global.excluded_strings[excluded_string] = nil
        build_excluded_string_table(player)
        build_train_schedule_group_report(player)
    elseif event.element.name == "delete_all_excluded_strings_button" then
        player_global.excluded_strings = {}
        build_excluded_string_table(player)
        build_train_schedule_group_report(player)
    elseif event.element.tags.train_schedule_create_blueprint_button then
        local template_train
        for _, id in pairs(event.element.tags.template_train_ids) do
            local template_option = get_train_by_id(id)
            if template_option then
                local orientation = template_option.front_stock.orientation
                if is_vertical(orientation) or is_horizontal(orientation) then 
                    template_train = template_option
                    break
                end
            end
        end
        if template_train == nil then
            player.create_local_flying_text{text="All trains with this schedule have been removed or have yucky orientations.", create_at_cursor=true}
            return
        end
        local surface_name = event.element.tags.surface
        create_blueprint_from_train(player, template_train, surface_name)
    end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
    local player = game.get_player(event.player_index)
    if not player then return end -- assure vscode that player is not nil
    local player_global = global.players[player.index]
    if event.element.name == "current_surface_checkbox" then
        player_global.only_current_surface = not player_global.only_current_surface
        build_train_schedule_group_report(player)
    elseif event.element.name == "show_satisfied_checkbox" then
        player_global.show_satisfied = not player_global.show_satisfied
        build_train_schedule_group_report(player)
    elseif event.element.name == "show_invalid_checkbox" then
        player_global.show_invalid = not player_global.show_invalid
        build_train_schedule_group_report(player)
    elseif event.element.tags.associated_string then
        player_global.excluded_strings[event.element.tags.associated_string].enabled = not player_global.excluded_strings[event.element.tags.associated_string].enabled
        build_excluded_string_table(player)
        build_train_schedule_group_report(player)
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
    if config_changed_data.mod_changes["train_limit_linter"] then
        for _, player in pairs(game.players) do
            local player_global = global.players[player.index]
            if player_global.elements.main_frame ~= nil then
                toggle_interface(player)
            else
                player.opened = nil
            end
        end
    end
end)

-- TODO: add exclusions for surfaces
-- TODO: add fuel in new trains
-- TODO: fuel selector?
-- TODO: allow non-cardinal-direction trains to serve as templates (probably going to involve just making new blueprint entities?)