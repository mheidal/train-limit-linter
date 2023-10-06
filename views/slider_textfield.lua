local constants = require("constants")

Exports = {}

-- Adds a horizontal flow containing a slider and a textfield to the parent element.
-- The slider and the textfield will reflect each other's values.
function Exports.add_slider_textfield(parent, action, value, value_step, minimum_value, maximum_value, enabled_condition)
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
    local textfield = slider_textfield_flow.add{
        type="textfield",
        name="textfield",
        tags={
            action=action,
            slider_textfield=true
        },
        style="slider_value_textfield",
        text=tostring(value),
        enabled=enabled_condition
    }
end

function Exports.update_slider_value(slider_textfield_flow)
    local slider = slider_textfield_flow.slider
    local textfield = slider_textfield_flow.textfield
    slider.slider_value = tonumber(textfield.text)
end

function Exports.update_textfield_value(slider_textfield_flow)
    local slider = slider_textfield_flow.slider
    local textfield = slider_textfield_flow.textfield
    textfield.text = tostring(slider.slider_value)
end

return Exports