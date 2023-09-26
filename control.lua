-- Returns an array of arrays of trains which share a schedule.
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

local function get_train_station_limits(player, train_schedule_group, surface)
    local sum_of_limits = 0
    local shared_schedule = train_schedule_group[1].schedule

    for _, record in pairs(shared_schedule.records) do
        for _, train_stop in pairs(surface.get_train_stops({name=record.station})) do    
            -- no train limit is implemented as limit == 2 ^ 32 - 1
            if train_stop.trains_limit == (2 ^ 32) - 1 then
                return "x" -- "x" used as a sentinal value (how I miss you, Rust)
            else
                sum_of_limits = sum_of_limits + train_stop.trains_limit
            end
        end
    end
    return sum_of_limits
end

-- TODO
local function create_blueprint_from_train()

end

local function build_train_schedule_group_report(player)
    local player_global = global.players[player.index]
    local surface_train_schedule_groups_pairs = get_train_schedule_groups_by_surface()
    local report_frame = player_global.elements.report_frame
    report_frame.clear()

    if player_global.train_report_exists then
        for _, surface_train_schedule_groups_pair in pairs(surface_train_schedule_groups_pairs) do
            local surface = surface_train_schedule_groups_pair.surface
            if player_global.only_current_surface and surface.name ~= player.surface.name then goto continue end

            local train_schedule_groups = surface_train_schedule_groups_pair.train_schedule_groups
            for key, train_schedule_group in pairs(train_schedule_groups) do
                local train_limit_sum = get_train_station_limits(player, train_schedule_group, surface)

                local invalid = (train_limit_sum == "x")
                local satisfied = not invalid and (train_limit_sum - #train_schedule_group == 1)

                if (
                    (player_global.show_satisfied and satisfied)
                    or (player_global.show_invalid and invalid)
                    or (not invalid and not satisfied)
                    ) then
                    local caption = key .. " --- " .. tostring(#train_schedule_group) .. "/" .. tostring(train_limit_sum)
                    report_frame.add{type="button", style="rb_list_box_item", caption=caption}
                end
            end
        end
        ::continue::
    end
end

local function get_pin_style(player)
    local player_global = global.players[player.index]
    return player_global.window_pinned and "flib_selected_frame_action_button" or "frame_action_button"
end

local function get_pin_sprite(player)
    local player_global = global.players[player.index]
    return player_global.window_pinned and "tll_pin_black" or "tll_pin_white"
end

local function initialize_global(player)
    global.players[player.index] = {
        train_report_exists = false,
        only_current_surface = true,
        show_satisfied = true, -- satisfied when sum of train limits is 1 greater than sum of trains
        show_invalid = false, -- invalid when train limits are not set for all stations in name group,
        window_pinned = false,
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

    local titlebar_flow = main_frame.add{
        type="flow",
        direction="horizontal",
        name="tll_titlebar_flow",
        style="flib_titlebar_flow"
    }
    titlebar_flow.drag_target = main_frame
    titlebar_flow.add{type="label", style="frame_title", caption={"tll.main_frame_header"}}
    titlebar_flow.add{type="empty-widget", style="flib_titlebar_drag_handle", ignored_by_interaction=true}

    local pin_style = get_pin_style(player)
    local pin_sprite = get_pin_sprite(player)
    local pin_button = titlebar_flow.add{type="sprite-button", name="pin_window_button", style=pin_style, sprite=pin_sprite, hovered_sprite="tll_pin_black", tooltip={"tll.keep_open"}}
    player_global.elements.pin_button = pin_button

    titlebar_flow.add{type="sprite-button", name="close_window_button", style="frame_action_button", sprite = "utility/close_white", tooltip={"tll.close"}}

    local content_frame = main_frame.add{type="frame", name="content_frame", direction="vertical", style="ugg_content_frame"}
    local controls_flow = content_frame.add{type="flow", name="controls_flow", direction="vertical", style="ugg_controls_flow"}

    controls_flow.add{type="checkbox", name="current_surface_checkbox", caption={"tll.only_player_surface"}, state=player_global.only_current_surface}
    controls_flow.add{type="checkbox", name="show_satisfied_checkbox", caption={"tll.show_satisfied"}, state=player_global.show_satisfied}
    controls_flow.add{type="checkbox", name="show_invalid_checkbox", caption={"tll.show_invalid"}, state=player_global.show_invalid}
    controls_flow.add{type="button", name="train_report_button", caption={"tll.train_report_button_create"}}


    local report_frame = content_frame.add{type="scroll-pane", name="report_table", style="rb_list_box_scroll_pane"}
    player_global.elements.report_frame = report_frame

    build_train_schedule_group_report(player)

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
        player_global.train_report_exists = false
    end
end

script.on_event("tll_toggle_interface", function(event)
    local player = game.get_player(event.player_index)
    toggle_interface(player)
end)

script.on_event(defines.events.on_gui_click, function (event)
    local player = game.get_player(event.player_index)
    local player_global = global.players[player.index]
    if event.element.name == "train_report_button" then
        event.element.caption = {"tll.train_report_button_update"}
        player_global.train_report_exists = true
        build_train_schedule_group_report(player)
    elseif event.element.name == "close_window_button" then
        toggle_interface(player)
    elseif event.element.name == "pin_window_button" then
        player_global.window_pinned = not player_global.window_pinned
        player_global.elements.pin_button.style = get_pin_style(player)
        player_global.elements.pin_button.sprite = get_pin_sprite(player)
    end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
    local player = game.get_player(event.player_index)
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
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    if event.element and event.element.name == "tll_main_frame" then
        local player = game.get_player(event.player_index)
        local player_global = global.players[player.index]
        if not player_global.window_pinned then
            toggle_interface(player)
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

-- TODO: break train group reports into sections based on surface
-- TODO: add click-for-blueprint functionality
-- TODO: fix pinning behavior