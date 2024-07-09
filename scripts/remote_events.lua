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
    local se = constants.supported_interfaces.space_exploration
    local teleport_started_event = "get_on_train_teleport_started_event"
    local teleport_finished_event = "get_on_train_teleport_finished_event"
    local remote_interfaces = remote.interfaces
    if (
        remote_interfaces[se]
        and remote_interfaces[se][teleport_started_event]
        and remote_interfaces[se][teleport_finished_event]
    ) then
        script.on_event(
            remote.call(se, teleport_started_event, {}--[[@as table]])--[[@as string]],
            train_teleport_start_handler
        )
        script.on_event(
            remote.call(se, teleport_finished_event, {}--[[@as table]])--[[@as string]],
            train_teleport_finish_handler
        )
    end
end

return TLLRemoteEvents