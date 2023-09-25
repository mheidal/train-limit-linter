
-- Returns an array of arrays of trains which share a schedule.
local function get_train_schedule_groups()
    local function train_schedule_to_key(schedule)
        local key = ""
        for _, record in pairs(schedule.records) do
            if not record.temporary and record.station then
                key = key .. " " .. record.station
            end
        end
        return key
    end

    local train_schedule_groups = {}

    for _, surface in pairs(game.surfaces) do
        for _, train in pairs(surface.get_trains()) do
            local schedule = train.schedule
            if schedule then
                local key = train_schedule_to_key(schedule)
                train_schedule_groups[key] = train_schedule_groups[key] or {}
                table.insert(train_schedule_groups[key], train)
            end
        end
    end
    return train_schedule_groups
end

local function get_train_station_limits(player, train_schedule_group, excluded_names)
    local function contains(table, item)
        for _, v in pairs(table) do
            if v == item then return true end
        end
        return false
    end

    local shared_schedule = train_schedule_group[1].schedule
    

end

local function build_train_schedule_group_report(player)
    local player_global = global.players[player.index]
    local train_schedule_groups = get_train_schedule_groups()
    local report_frame = player_global.elements.report_frame
    report_frame.clear()
    if player_global.train_report_exists then
        for key, train_schedule_group in pairs(train_schedule_groups) do
            local caption = tostring(#train_schedule_group) .. " train:" .. key
            report_frame.add{type="button", style="rb_list_box_item", caption=caption}
        end
    end
end

local function initialize_global(player)
    global.players[player.index] = {
        train_report_exists = false,
        elements = {}
    }
end

local function build_interface(player)
    local player_global = global.players[player.index]

    local screen_element = player.gui.screen
    local main_frame = screen_element.add{type="frame", name="tll_main_frame", caption={"tll.main_frame_header"}}
    main_frame.style.size = {600, 480}
    main_frame.auto_center = true

    player.opened = main_frame
    player_global.elements.main_frame = main_frame

    local content_frame = main_frame.add{type="frame", name="content_frame", direction="vertical", style="ugg_content_frame"}
    local controls_flow = content_frame.add{type="flow", name="controls_flow", direction="horizontal", style="ugg_controls_flow"}

    local train_report_button = controls_flow.add{type="button", name="train_report_button", caption={"tll.train_report_button_create"}}

    local report_frame = content_frame.add{type="scroll-pane", name="report_table", style="rb_list_box_scroll_pane"}
    player_global.elements.report_frame = report_frame

    build_train_schedule_group_report(player)

end

local function toggle_interface(player)
    local player_global = global.players[player.index]
    local main_frame = player_global.elements.main_frame
    if main_frame == nil then
        build_interface(player)
    else
        main_frame.destroy()
        player_global.elements.main_frame = nil
        player_global.train_report_exists = false
    end
end

script.on_event("tll_toggle_interface", function(event)
    local player = game.get_player(event.player_index)
    toggle_interface(player)
end)

script.on_event(defines.events.on_gui_click, function (event)
    if event.element.name == "train_report_button" then
        local player = game.get_player(event.player_index)
        local player_global = global.players[player.index]
        event.element.caption = {"tll.train_report_button_update"}
        player_global.train_report_exists = true
        build_train_schedule_group_report(player)
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    if event.element and event.element.name == "tll_toggle_interface" then
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
    if freeplay then -- TODO: remove this
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
            end
        end
    end
end)