local constants = require("constants")

local slider_textfield = require("views/slider_textfield")

Exports = {}

local function build_blueprint_snap_selector(player, parent)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local config = player_global.model.blueprint_configuration

    local blueprint_snap_selector_flow = parent.add{type="flow", direction="vertical"}
    blueprint_snap_selector_flow.style.top_margin = 5
    blueprint_snap_selector_flow.add{
        type="checkbox",
        state=config.snap_enabled,
        tags={action=constants.actions.toggle_blueprint_snap},
        caption={"tll.enable_blueprint_snap"}
    }
    blueprint_snap_selector_flow.add{type="label", caption={"tll.set_snap_width"}}
    slider_textfield.add_slider_textfield(
        blueprint_snap_selector_flow,
        {action=constants.actions.set_blueprint_snap_width},
        config.snap_width,
        2,
        2,
        20,
        config.snap_enabled,
        false
    )
    local snap_direction_flow = parent.add{type="flow", direction="horizontal"}
    snap_direction_flow.style.horizontally_stretchable = true
    snap_direction_flow.add{type="label", caption={"tll.set_snap_direction"}}

    local switch_state = (config.snap_direction == constants.snap_directions.horizontal) and "left" or "right"

    local snap_direction_switch = snap_direction_flow.add{
        type="switch",
        switch_state=switch_state,
        tags = {action=constants.actions.toggle_blueprint_snap_direction},
        style="switch",
        left_label_caption={"tll.horizontal"},
        right_label_caption={"tll.vertical"},
        enabled=config.snap_enabled
    }
    snap_direction_switch.style.vertical_align = "center"
end

Exports.build_blueprint_snap_selector = build_blueprint_snap_selector

return Exports