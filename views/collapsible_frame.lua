local constants = require("constants")
local Exports = {}

local content_flow_name = "content_flow"

---@param parent LuaGuiElement
---@param collapsible_frame_name LocalisedString
---@return LuaGuiElement
function Exports.build_collapsible_frame(parent, collapsible_frame_name)
    local collapsible_frame = parent.add{
        type="frame",
        name=collapsible_frame_name,
        direction="vertical",
        style="subpanel_frame"
    }
    collapsible_frame.style.horizontally_stretchable = true

    return collapsible_frame
end

---@param collapsible_frame LuaGuiElement
---@param caption LocalisedString
---@param caption_tooltip LocalisedString
---@param content_visible boolean
---@return LuaGuiElement
function Exports.build_collapsible_frame_contents(collapsible_frame, caption, caption_tooltip, content_visible)
    collapsible_frame.clear()
    local show_hide_flow = collapsible_frame.add{
        type="flow",
        direction="horizontal",
        style="player_input_horizontal_flow",
    }

    local show_hide_button_sprite = content_visible and "utility/collapse" or "utility/expand"
    local show_hide_button_hovered_sprite = content_visible and "utility/collapse_dark" or "utility/expand_dark"

    show_hide_flow.add{
        type="sprite-button",
        style="control_settings_section_button",
        tags={action=constants.actions.toggle_collapsible_frame_content_visible},
        sprite=show_hide_button_sprite,
        hovered_sprite=show_hide_button_hovered_sprite,
    }

    show_hide_flow.add{type="label", style="caption_label", caption={"tll.tooltip_title", caption}, tooltip=caption_tooltip}

    local content_flow = collapsible_frame.add{
        type="flow",
        direction="vertical",
        visible=content_visible,
        name=content_flow_name
    }
    return content_flow
end


function Exports.toggle_collapsible_frame_visible(show_hide_button)
    local collapsible_frame = show_hide_button.parent.parent
    collapsible_frame[content_flow_name].visible = not collapsible_frame[content_flow_name].visible
    show_hide_button.sprite = collapsible_frame[content_flow_name].visible and "utility/collapse" or "utility/expand"
    show_hide_button.hovered_sprite = collapsible_frame[content_flow_name].visible and "utility/collapse_dark" or "utility/expand_dark"
end

return Exports