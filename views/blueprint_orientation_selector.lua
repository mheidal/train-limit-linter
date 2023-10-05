local constants = require("constants")

Exports = {}

local function build_blueprint_orientation_selector(selected_orientation, parent)

    local direction_selector_flow = parent.add{type="flow", direction="vertical"}
    direction_selector_flow.add{type="label", caption="Set train direction in blueprints."}
    local direction_table = direction_selector_flow.add{type="table", column_count=3}

    local orientations = constants.orientations
    local ordered_orientations = {
        orientations.ul,
        orientations.u,
        orientations.ur,
        orientations.l,
        -1,
        orientations.r,
        orientations.dl,
        orientations.d,
        orientations.dr
    }

    for _, orientation in pairs(ordered_orientations) do
        if orientation == -1 then
            direction_table.add{type="empty-widget"}
        else
            local button_style = (orientation == selected_orientation) and "yellow_slot_button" or "recipe_slot_button"
            direction_table.add{type="sprite-button", style=button_style, tags={action=constants.actions.set_blueprint_orientation, orientation=orientation}}
        end
    end
end

Exports.build_blueprint_orientation_selector = build_blueprint_orientation_selector

return Exports