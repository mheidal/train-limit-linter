local constants = require("constants")

Exports = {}

Exports.textfield_name = "icon_selector_textfield"
Exports.icon_selector_button_name = "icon_selector_button"
Exports.enter_button_name = "icon_selector_enter_button"

function Exports.build_icon_selector_textfield(parent, entry_button_tooltip)
    parent.add{
        type="textfield",
        name = Exports.textfield_name
    }

    parent.add{
        type="choose-elem-button",
        elem_type="signal",
        signal={type="virtual", name="tll-select-icon"},
        name = Exports.icon_selector_button_name,
        tags={action=constants.actions.icon_selector_icon_selected} -- weird name
    }

    parent.add{
        type="sprite-button",
        tags={action=constants.actions.icon_selector_textfield_apply},
        style="item_and_count_select_confirm",
        sprite="utility/enter",
        tooltip=entry_button_tooltip,
        name = Exports.enter_button_name
    }
end

function Exports.handle_icon_selection(element)
    if element.parent and element.parent[Exports.textfield_name] then
        local textfield = element.parent[Exports.textfield_name]
        local elem_value = element.elem_value
        textfield.text = textfield.text .. Exports.item_name_to_rich_text(elem_value)
        textfield.focus()
    end
    element.elem_value = {
        type="virtual",
        name="tll-select-icon"
    }
end

function Exports.item_name_to_rich_text(elem_value)
    if elem_value.type == "item" then
        return "[img=item." .. elem_value.name .. "]"
    elseif elem_value.type == "fluid" then
        return "[img=fluid." .. elem_value.name .. "]"
    elseif elem_value.type == "virtual" then
        return "[img=virtual-signal." .. elem_value.name .. "]"
    end
    return ""
end

return Exports