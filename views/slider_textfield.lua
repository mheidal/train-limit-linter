local constants = require("constants")

Exports = {}

-- Adds a horizontal flow containing a slider and a textfield to the parent element.
-- The slider and the textfield will reflect each other's values.
---@param parent LuaGuiElement
---@param tags table
---@param value number
---@param value_step number
---@param minimum_value number
---@param maximum_value number
---@param enabled_condition boolean
---@param cap_textfield_value boolean
---@return LuaGuiElement -- the flow containing the two
function Exports.add_slider_textfield(parent, tags, value, value_step, minimum_value, maximum_value, enabled_condition, cap_textfield_value)
    local slider_textfield_flow = parent.add{type="flow", direction="horizontal"}

    local slider_tags = {
        slider_textfield=true,
    }
    local textfield_tags = {
        slider_textfield=true,
        cap_textfield_value=cap_textfield_value
    }

    for tag, tag_value in pairs(tags) do
        slider_tags[tag] = tag_value
        textfield_tags[tag] = tag_value
    end

    local slider = slider_textfield_flow.add{
        type="slider",
        name="slider",
        tags=slider_tags,
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
        tags=textfield_tags,
        style="slider_value_textfield",
        text=tostring(value),
        enabled=enabled_condition,
        negative_allowed = negative_allowed,
        numeric=true,
    }
    return slider_textfield_flow
end

---@param slider_textfield_flow LuaGuiElement
---@param new_value number?
function Exports.update_slider_value(slider_textfield_flow, new_value)
    
    local slider = slider_textfield_flow.slider
    if not slider then return end
    if new_value == nil then
        local textfield = slider_textfield_flow.textfield
        if not textfield then return end
        new_value = textfield.text ~= "" and tonumber(textfield.text) or 0
        if textfield.tags.cap_textfield_value then
            if new_value > slider.get_slider_maximum() then
                new_value = slider.get_slider_maximum()
                textfield.text = tostring(new_value)
            end
        end
    end
    slider.slider_value = new_value
end

---@param slider_textfield_flow LuaGuiElement
---@param new_value number?
function Exports.update_textfield_value(slider_textfield_flow, new_value)
    if not new_value then
        local slider = slider_textfield_flow.slider
        if not slider then return end
        new_value = slider.slider_value
    end
    local textfield = slider_textfield_flow.textfield
    if not textfield then return end
    textfield.text = tostring(new_value)
end

return Exports