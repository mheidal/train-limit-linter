local constants = require("constants")

Exports = {}

local function build_blueprint_orientation_selector(selected_orientation, parent)

    local direction_selector_flow = parent.add{type="flow", direction="vertical"}
    direction_selector_flow.add{type="label", caption={"tll.set_direction"}, tooltip={"tll.set_direction_tooltip"}}
    local selected_direction_label = direction_selector_flow.add{type="label"}

    local direction_table = direction_selector_flow.add{type="table", column_count=3}

    local orientations = constants.orientations
    local ordered_orientations = {
        {"tll.orientation_northwest", orientations.ul},
        {"tll.orientation_north", orientations.u},
        {"tll.orientation_northeast", orientations.ur},
        {"tll.orientation_west", orientations.l},
        -1,
        {"tll.orientation_east", orientations.r},
        {"tll.orientation_southwest", orientations.dl},
        {"tll.orientation_south", orientations.d},
        {"tll.orientation_southeast", orientations.dr},
    }

    for _, name_orientation_tuple in pairs(ordered_orientations) do
        if name_orientation_tuple == -1 then
            direction_table.add{type="empty-widget"}
        else
            local caption, orientation = table.unpack(name_orientation_tuple)
            local button_style
            if orientation == selected_orientation then
                selected_direction_label.caption = {"", {"tll.selected_direction"}, " ", {caption}, "."}
                button_style = "yellow_slot_button"
            else
                button_style = "recipe_slot_button"
            end
            direction_table.add{type="sprite-button", style=button_style, tags={action=constants.actions.set_blueprint_orientation, orientation=orientation}}
        end
    end
end

Exports.build_blueprint_orientation_selector = build_blueprint_orientation_selector

return Exports