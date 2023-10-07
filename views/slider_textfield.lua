local constants = require("constants")

Exports = {}

-- Adds a horizontal flow containing a slider and a textfield to the parent element.
-- The slider and the textfield will reflect each other's values.
---@param parent LuaGuiElement
---@param action string
---@param value number
---@param value_step number
---@param minimum_value number
---@param maximum_value number
---@param enabled_condition boolean
---@param cap_textfield_value boolean
function Exports.add_slider_textfield(parent, action, value, value_step, minimum_value, maximum_value, enabled_condition, cap_textfield_value)
    local slider_textfield_flow = parent.add{type="flow", direction="horizontal"}
    local slider = slider_textfield_flow.add{
        type="slider",
        name="slider",
        tags={
            action=action,
            slider_textfield=true,
        },
        value=value,
        value_step=value_step,
        minimum_value=minimum_value,
        maximum_value=maximum_value,
        style="notched_slider",
        enabled=enabled_condition
    }
    slider.style.horizontally_stretchable = true
    local negative_allowed = minimum_value < 0
    local textfield = slider_textfield_flow.add{
        type="textfield",
        name="textfield",
        tags={
            action=action,
            slider_textfield=true,
            cap_textfield_value=cap_textfield_value
        },
        style="slider_value_textfield",
        text=tostring(value),
        enabled=enabled_condition,
        negative_allowed = negative_allowed,
        numeric=true,
    }
end

function Exports.update_slider_value(slider_textfield_flow)
    local slider = slider_textfield_flow.slider
    local textfield = slider_textfield_flow.textfield
    local new_value = textfield.text ~= "" and tonumber(textfield.text) or 0
    if textfield.tags.cap_textfield_value then
        if new_value > slider.get_slider_maximum() then
            new_value = slider.get_slider_maximum()
            textfield.text = tostring(new_value)
        end
    end
    slider.slider_value = new_value
end

function Exports.update_textfield_value(slider_textfield_flow)
    local slider = slider_textfield_flow.slider
    local textfield = slider_textfield_flow.textfield
    textfield.text = tostring(slider.slider_value)
end

return Exports