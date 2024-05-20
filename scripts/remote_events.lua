local interfaces = require("views.interfaces")

local TLLRemoteEvents = {}

local function train_teleport_start_handler(event)
    -- increment count of trains teleporting
    global.model.space_exploration_trains_teleporting_count = global.model.space_exploration_trains_teleporting_count + 1
    global.model.delay_rebuilding_interface = true
end

local function train_teleport_finish_handler(event)
    -- decrement count of trains teleporting
    global.model.space_exploration_trains_teleporting_count = global.model.space_exploration_trains_teleporting_count - 1

    -- edge case: a train was already teleporting when we began tracking how many trains were teleporting
    if global.model.space_exploration_trains_teleporting_count < 0 then
        global.model.space_exploration_trains_teleporting_count = 0
    end

    -- refresh guis
    if global.model.space_exploration_trains_teleporting_count == 0 then
        if global.model.delay_rebuilding_interface then
            for _, player in pairs(game.players) do
                interfaces.rebuild_interfaces(player)
            end
        end
        global.model.delay_rebuilding_interface = false
    end
end

function TLLRemoteEvents.handle_remote_events()
    local remote_events = {}
    if remote.interfaces["space-exploration"] then
        remote_events.get_on_train_teleport_started_event = remote.call("space-exploration", "get_on_train_teleport_started_event", {})
        script.on_event(remote_events.get_on_train_teleport_started_event, train_teleport_start_handler)
        remote_events.get_on_train_teleport_finished_event = remote.call("space-exploration", "get_on_train_teleport_finished_event", {})
        script.on_event(remote_events.get_on_train_teleport_finished_event, train_teleport_finish_handler)
    end
end

return TLLRemoteEvents