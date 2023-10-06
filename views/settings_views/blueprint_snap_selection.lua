local constants = require("constants")

local slider_textfield = require("views/slider_textfield")

Exports = {}

local function build_blueprint_snap_selector(player, parent)
    local player_global = global.players[player.index]
    local config = player_global.model.blueprint_configuration

    local blueprint_snap_selector_flow = parent.add{type="flow", direction="vertical"}
    blueprint_snap_selector_flow.style.top_margin = 5
    blueprint_snap_selector_flow.add{type="checkbox", state=config.snap_enabled, caption={"tll.enable_blueprint_snap"}}
    blueprint_snap_selector_flow.add{type="label", caption={"tll.set_snap_width"}}
    slider_textfield.add_slider_textfield(
        blueprint_snap_selector_flow,
        constants.actions.set_blueprint_snap_width,
        config.snap_width,
        2,
        2,
        20,
        config.snap_enabled
    )
end

Exports.build_blueprint_snap_selector = build_blueprint_snap_selector

return Exports