local constants = require("constants")

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
---@param keyword_list_name string
local function build_keyword_tab(
    parent,
    label_caption,
    label_tooltip,
    apply_button_action,
    delete_all_keywords_action,
    toggle_keyword_action,
    delete_keyword_action,
    keyword_list,
    keyword_list_name
)
    parent.clear()

    local control_flow = parent.add{type="flow", direction="vertical", style="tll_controls_flow"}
    control_flow.style.bottom_margin = 5
    control_flow.add{type="label", caption=label_caption, tooltip=label_tooltip}
    local textfield_flow = control_flow.add{type="flow", direction="horizontal"}
    icon_selector_textfield.build_icon_selector_textfield(textfield_flow, {action=apply_button_action})
    textfield_flow.add{
        type="sprite-button",
        tags={action=apply_button_action},
        style="item_and_count_select_confirm",
        sprite="utility/enter",
        tooltip={"tll.apply_change"},
        name = Exports.enter_button_name
    }

    textfield_flow.add{
        type="sprite-button",
        tags={
            action=constants.actions.open_modal,
            modal_function=constants.modal_functions.train_stop_name_selector,
            args={}
        },
        style="tool_button",
        sprite="utility/station_name",
        tooltip={"tll.train_stop_name_selector_button_tooltip"}
    }

    textfield_flow.add{
        type="sprite-button",
        tags={
            action=constants.actions.open_modal,
            modal_function=constants.modal_functions.import_keyword_list,
            args={keywords=keyword_list_name}
        },
        style="tool_button",
        sprite="utility/import",
        tooltip={"tll.import_keywords"}
    }

    textfield_flow.add{
        type="sprite-button",
        tags={
            action=constants.actions.open_modal,
            modal_function=constants.modal_functions.export_keyword_list,
            args={keywords=keyword_list_name}
        },
        style="tool_button",
        sprite="utility/export",
        tooltip={"tll.export_keywords"}
    }

    local spacer = textfield_flow.add{type="empty-widget"}
    spacer.style.horizontally_stretchable = true
    textfield_flow.add{type="sprite-button", tags={action=delete_all_keywords_action}, style="tool_button_red", sprite="utility/trash", tooltip={"tll.delete_all_keywords"}}

    local keyword_table_scroll_pane = parent.add{type="scroll-pane", direction="vertical"}
    keyword_table_scroll_pane.style.vertically_stretchable = true

    if keyword_list:get_number_of_keywords() == 0 then
        keyword_table_scroll_pane.add{type="label", caption={"tll.no_keywords"}}
        return
    end

    for keyword, string_data in pairs(keyword_list:get_keywords()) do
        local keyword_line_flow = keyword_table_scroll_pane.add{type="flow", direction="horizontal"}
        keyword_line_flow.add{type="checkbox", state=string_data.enabled, tags={action=toggle_keyword_action, keyword=keyword}}
        keyword_line_flow.add{type="label", caption=keyword}
        local spacer = keyword_line_flow.add{type="empty-widget"}
        spacer.style.horizontally_stretchable = true
        keyword_line_flow.add{type="sprite-button", tags={action=delete_keyword_action, keyword=keyword}, sprite="utility/trash", style="tool_button_red"}
    end

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
        player_global.model.excluded_keywords,
        constants.keyword_lists.exclude
    )
end


function Exports.build_hide_tab(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local hide_content_frame = player_global.view.hide_content_frame
    if not hide_content_frame then return end

    build_keyword_tab(
        hide_content_frame,
        {"tll.add_hidden_keyword"},
        {"tll.add_hidden_keyword_tooltip"},
        constants.actions.hide_textfield_apply,
        constants.actions.delete_all_hidden_keywords,
        constants.actions.toggle_hidden_keyword,
        constants.actions.delete_hidden_keyword,
        player_global.model.hidden_keywords,
        constants.keyword_lists.hide
    )

end

return Exports