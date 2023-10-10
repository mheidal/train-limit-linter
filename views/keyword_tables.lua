local utils = require("utils")
local constants = require("constants")

Exports = {}

---@param keywords TLLKeywordList
---@param parent LuaGuiElement
---@param toggle_keyword_enabled_tag string
---@param delete_action_tag string
local function build_keyword_table(keywords, parent, toggle_keyword_enabled_tag, delete_action_tag)
    if utils.get_table_size(keywords) == 0 then
        parent.add{type="label", caption={"tll.no_keywords"}}
        return
    end
    for keyword, string_data in pairs(keywords.toggleable_items) do
        local excluded_keyword_line = parent.add{type="flow", direction="horizontal"}
        excluded_keyword_line.add{type="checkbox", state=string_data.enabled, tags={action=toggle_keyword_enabled_tag, keyword=keyword}}
        excluded_keyword_line.add{type="label", caption=keyword}
        local spacer = excluded_keyword_line.add{type="empty-widget"}
        spacer.style.horizontally_stretchable = true
        excluded_keyword_line.add{type="sprite-button", tags={action=delete_action_tag, keyword=keyword}, sprite="utility/trash", style="tool_button_red"}
    end
end

Exports.build_keyword_table = build_keyword_table

return Exports