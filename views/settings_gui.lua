
local constants = require("constants")

Exports = {}

local function build_blueprint_orientation_selector(selected_orientation, parent)

    local direction_selector_flow = parent.add{type="flow", direction="vertical"}
    direction_selector_flow.add{type="label", caption="Set train direction in blueprints."}
    local direction_table = direction_selector_flow.add{type="table", column_count=3}

    for orientation_name, orientation in pairs(constants.orientations) do
        local button_style = (orientation == selected_orientation) and "yellow_slot_button" or "recipe_slot_button"
        direction_table.add{type="sprite-button", style=button_style, tags={action=constants.actions.set_blueprint_orientation, orientation=orientation}, caption=orientation_name}
        if orientation_name == "l" then
            direction_table.add{type="empty-widget"}
        end
    end
    --[[
    direction_table.add{type="sprite-button", tags={action=constants.actions.set_blueprint_orientation, orientation=constants.orientations.ul}}
    direction_table.add{type="sprite-button", tags={action=constants.actions.set_blueprint_orientation, orientation=constants.orientations.u}}
    direction_table.add{type="sprite-button", tags={action=constants.actions.set_blueprint_orientation, orientation=constants.orientations.ur}}

    direction_table.add{type="sprite-button", tags={action=constants.actions.set_blueprint_orientation, orientation=constants.orientations.l}}
    direction_table.add{type="empty-widget"}
    direction_table.add{type="sprite-button", tags={action=constants.actions.set_blueprint_orientation, orientation=constants.orientations.r}}

    direction_table.add{type="sprite-button", tags={action=constants.actions.set_blueprint_orientation, orientation=constants.orientations.dl}}
    direction_table.add{type="sprite-button", tags={action=constants.actions.set_blueprint_orientation, orientation=constants.orientations.d}}
    direction_table.add{type="sprite-button", tags={action=constants.actions.set_blueprint_orientation, orientation=constants.orientations.dr}}
    ]]
end

local function build_settings_gui(player)
    local player_global = global.players[player.index]

    if player_global.view.settings_main_frame ~= nil then
        player_global.view.settings_main_frame.destroy()
    end

    local screen_element = player.gui.screen

    local settings_main_frame = screen_element.add{
        type="frame",
        name="tll_settings_main_frame",
        direction="vertical"
    }
    settings_main_frame.style.size = {350, 400}

    settings_main_frame.auto_center = true
    player.opened = settings_main_frame
    player_global.view.settings_main_frame = settings_main_frame

    local titlebar_flow = settings_main_frame.add{
        type="flow",
        direction="horizontal",
        name="tll_titlebar_flow",
        style="flib_titlebar_flow"
    }
    titlebar_flow.drag_target = settings_main_frame
    titlebar_flow.add{type="label", style="frame_title", caption={"tll.settings_gui_header"}}
    titlebar_flow.add{type="empty-widget", style="flib_titlebar_drag_handle", ignored_by_interaction=true}

    titlebar_flow.add{type="sprite-button", tags={action=constants.actions.close_settings_gui}, style="frame_action_button", sprite = "utility/close_white", tooltip={"tll.close"}}

    build_blueprint_orientation_selector(player_global.model.blueprint_configuration.new_blueprint_orientation, settings_main_frame)

end

local function toggle_settings_gui(player)
    local player_global = global.players[player.index]
    if player_global.view.settings_main_frame then
        player_global.view.settings_main_frame.destroy()
        if player_global.view.main_frame then
            player.opened = player_global.view.main_frame
        end
    else
        build_settings_gui(player)
    end
end

Exports.build_settings_gui = build_settings_gui
Exports.toggle_settings_gui = toggle_settings_gui

return Exports