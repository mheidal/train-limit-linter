local constants = require("constants")

local keyword_tables = require("views/keyword_tables")
local icon_selector_textfield = require("views/icon_selector_textfield")

Exports = {}

---@param parent LuaGuiElement
---@param label_caption LocalisedString
---@param label_tooltip LocalisedString
---@param apply_button_action string
---@param delete_all_keywords_action string
---@param toggle_keyword_action string
---@param delete_keyword_action string
---@param keyword_list TLLKeywordList
local function build_keyword_tab(
    parent,
    label_caption,
    label_tooltip,
    apply_button_action,
    delete_all_keywords_action,
    toggle_keyword_action,
    delete_keyword_action,
    keyword_list
)
    parent.clear()

    local control_flow = parent.add{type="flow", direction="vertical", style="tll_controls_flow"}
    control_flow.style.bottom_margin = 5
    control_flow.add{type="label", caption=label_caption, tooltip=label_tooltip}
    local textfield_flow = control_flow.add{type="flow", direction="horizontal"}
    icon_selector_textfield.build_icon_selector_textfield(textfield_flow, {"tll.apply_change"}, apply_button_action)
    local spacer = textfield_flow.add{type="empty-widget"}
    spacer.style.horizontally_stretchable = true
    textfield_flow.add{type="sprite-button", tags={action=delete_all_keywords_action}, style="tool_button_red", sprite="utility/trash", tooltip={"tll.delete_all_keywords"}}

    local keyword_table_scroll_pane = parent.add{type="scroll-pane", direction="vertical"}
    keyword_table_scroll_pane.style.vertically_stretchable = true

    keyword_tables.build_keyword_table(
        keyword_list,
        keyword_table_scroll_pane,
        toggle_keyword_action,
        delete_keyword_action
    )
end

function Exports.build_exclude_tab(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local exclude_content_frame = player_global.view.exclude_content_frame
    if not exclude_content_frame then return end

    build_keyword_tab(
        exclude_content_frame,
        {"tll.add_excluded_keyword"},
        {"tll.add_excluded_keyword_tooltip"},
        constants.actions.exclude_textfield_apply,
        constants.actions.delete_all_excluded_keywords,
        constants.actions.toggle_excluded_keyword,
        constants.actions.delete_excluded_keyword,
        player_global.model.excluded_keywords
    )
end


function Exports.build_hide_tab(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local hide_content_frame = player_global.view.hide_content_frame
    if not hide_content_frame then return end

    build_keyword_tab(
        hide_content_frame,
        {"tll.add_excluded_keyword"},
        {"tll.add_excluded_keyword_tooltip"},
        constants.actions.hide_textfield_apply,
        constants.actions.delete_all_hidden_keywords,
        constants.actions.toggle_hidden_keyword,
        constants.actions.delete_hidden_keyword,
        player_global.model.hidden_keywords
    )

end

return Exports