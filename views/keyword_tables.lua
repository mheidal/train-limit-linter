local utils = require("utils")
local constants = require("constants")

exports = {}

local function build_excluded_keyword_table(player_global, excluded_keywords)
    local excluded_keywords_frame = player_global.view.excluded_keywords_frame
    excluded_keywords_frame.clear()
    build_keyword_table(excluded_keywords, excluded_keywords_frame, constants.actions.toggle_excluded_keyword, constants.actions.delete_excluded_keyword)
end

local function build_hidden_keyword_table(player_global, hidden_keywords)
    local hidden_keywords_frame = player_global.view.hidden_keywords_frame
    hidden_keywords_frame.clear()
    build_keyword_table(hidden_keywords, hidden_keywords_frame, constants.actions.toggle_hidden_keyword, constants.actions.delete_hidden_keyword)
end

function build_keyword_table(keywords, parent, toggle_keyword_enabled_tag, delete_action_tag)
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

exports.build_excluded_keyword_table = build_excluded_keyword_table
exports.build_hidden_keyword_table = build_hidden_keyword_table

return exports