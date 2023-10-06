local constants = require("constants")

local function build_blueprint_snap_selector(player, parent)
    local player_global = global.players[player.index]
    local blueprint_snap_selector_flow = parent.add{type="flow", direction="vertical"}
    blueprint_snap_selector_flow.add{type="checkbox", state=player.model.blueprint_configuration.snap_enabled, caption={"tll.enable_blueprint_snap"}}
    blueprint_snap_selector_flow.add{type="label", caption={"tll.set_snap_width"}}
    blueprint_snap_selector_flow.add{
        type="textfield",
        name="set_blueprint_snap_width_textfield",
        numeric=true,
        allow_decimal=false,
        allow_negative=false,
    }
end