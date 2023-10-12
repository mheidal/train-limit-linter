local constants = require("constants")

local Exports = {}

Exports.textfield_name = "icon_selector_textfield"
Exports.icon_selector_button_name = "icon_selector_button"
Exports.enter_button_name = "icon_selector_enter_button"

---@param parent any
---@param textfield_tags table?
function Exports.build_icon_selector_textfield(parent, textfield_tags)
    parent.add{
        type="textfield",
        name = Exports.textfield_name,
        tags=textfield_tags
    }

    local elem_button = parent.add{
        type="choose-elem-button",
        elem_type="signal",
        item_group="logistics",
        signal={type="virtual", name="tll-select-icon"},
        name = Exports.icon_selector_button_name,
        tags={action=constants.actions.icon_selector_icon_selected} -- weird name
    }
    elem_button.style.size = {28, 28}
end

function Exports.handle_icon_selection(element)
    if element.elem_value then
        if element.parent and element.parent[Exports.textfield_name] then
            local textfield = element.parent[Exports.textfield_name]
            local elem_value = element.elem_value
            textfield.text = textfield.text .. Exports.item_name_to_rich_text(elem_value)
            textfield.focus()
        end
    end
    element.elem_value = {
        type="virtual",
        name="tll-select-icon"
    }
end

function Exports.item_name_to_rich_text(elem_value)
    if elem_value.type == "item" then
        return "[item=" .. elem_value.name .. "]"
    elseif elem_value.type == "fluid" then
        return "[fluid=" .. elem_value.name .. "]"
    elseif elem_value.type == "virtual" then
        return "[virtual-signal=." .. elem_value.name .. "]"
    end
    return ""
end

function Exports.get_text_and_reset_textfield(apply_button_element)
    if apply_button_element.parent and apply_button_element.parent[Exports.textfield_name] then
        local textfield = apply_button_element.parent[Exports.textfield_name]
        local text = textfield.text
        textfield.text = ""
        return text
    end
    return ""
end

return Exports