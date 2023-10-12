local constants = require("constants")
local modal_content_data = require("models/modal_content_data")
local icon_selector_textfield = require("views/icon_selector_textfield")

-- This Exports works differently from the rest!
local Exports = {}

---@param player LuaPlayer
---@param parent LuaGuiElement
---@param args table?
---@return TLLModalContentData
Exports[constants.modal_functions.train_stop_name_selector] = function (player, parent, args)

    local content_frame = parent.add{type="frame", direction="vertical", name="modal_content_frame", style="inside_shallow_frame"}
    local search_bar = parent.add{type="flow", direction="horizontal"}
    local spacer = search_bar.add{type="empty-widget"}
    spacer.style.horizontally_stretchable = true
    local textfield_frame = search_bar.add{type="frame", direction="horizontal", style="search_popup_frame"}
    icon_selector_textfield.build_icon_selector_textfield(textfield_frame, {action=constants.actions.train_stop_name_selector_search})

    local search_button = search_bar.add{
        type="sprite-button",
        tags={
            action=constants.actions.open_modal,
        },
        style="tool_button",
        sprite="utility/search",
    }
    -- todo: toggle textfield frame
    -- todo: search table (probably a list of buttons?)

    return modal_content_data.TLLModalContentData:new()
end

return Exports