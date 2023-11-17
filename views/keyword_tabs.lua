local constants = require("constants")

local icon_selector_textfield = require("views.icon_selector_textfield")

local Exports = {}

---@param parent LuaGuiElement
---@param label_caption LocalisedString
---@param label_tooltip LocalisedString
---@param apply_button_action string
---@param delete_all_keywords_action string
---@param toggle_keyword_action string
---@param delete_keyword_action string
---@param keyword_list TLLKeywordList
---@param keyword_list_name string
---@return LuaGuiElement -- the textfield, so the train stop name selector can find it. Gross!
local function build_keyword_tab(
    parent,
    label_caption,
    label_tooltip,
    enter_text_action,
    apply_button_action,
    delete_all_keywords_action,
    toggle_keyword_action,
    delete_keyword_action,
    keyword_list,
    keyword_list_name
)
    local control_label_name = "keyword_tab_control_label"
    if not parent[control_label_name] then parent.add{type="label", name=control_label_name, caption=label_caption, tooltip=label_tooltip} end

    local control_flow_name = "keyword_tab_control_flow"
    local control_flow = parent[control_flow_name] or parent.add{
        type="flow",
        name=control_flow_name,
        direction="horizontal",
        style="tll_horizontal_controls_flow"
    }
    control_flow.style.bottom_margin = 5

    local textfield_flow_name = "keyword_tab_textfield_flow"
    local textfield_flow
    if control_flow[textfield_flow_name] then
        textfield_flow = control_flow[textfield_flow_name]
    else
        textfield_flow = control_flow.add{
            type="flow",
            name=textfield_flow_name,
            direction="horizontal"
        }
        icon_selector_textfield.build_icon_selector_textfield(textfield_flow, {action=enter_text_action})
        textfield_flow.add{
            type="sprite-button",
            tags={action=apply_button_action},
            style="item_and_count_select_confirm",
            sprite="utility/enter",
            tooltip={"tll.apply_change"},
        }
    end

    local button_flow_name = "keyword_tab_button_flow"
    local button_flow = control_flow[button_flow_name] or control_flow.add{
        type="flow",
        name=button_flow_name,
        direction="horizontal"
    }
    button_flow.clear()

    button_flow.add{
        type="sprite-button",
        tags={
            action=constants.actions.open_modal,
            modal_function=constants.modal_functions.train_stop_name_selector,
            args={keywords=keyword_list_name}
        },
        style="tool_button",
        sprite="utility/station_name",
        tooltip={"tll.train_stop_name_selector_button_tooltip"}
    }

    button_flow.add{type="empty-widget", style="tll_spacer"}

    button_flow.add{
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

    button_flow.add{
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

    if keyword_list:get_number_of_keywords() > 1 then
        button_flow.add{
            type="sprite-button",
            tags={action=delete_all_keywords_action},
            style="tool_button_red",
            sprite="utility/trash",
            tooltip={"tll.delete_all_keywords"}
        }
    else
        local spacer = button_flow.add{type="empty-widget"}
        spacer.style.width = 28
    end

    local scroll_pane_name = "scroll_pane_name"
    local keyword_table_scroll_pane = parent[scroll_pane_name] or parent.add{
            type="scroll-pane",
            direction="vertical",
            name=scroll_pane_name,
            style="tll_content_scroll_pane"
        }
    keyword_table_scroll_pane.clear()

    local any_keywords = false

    local no_keywords_label = keyword_table_scroll_pane.add{type="label", caption={"tll.no_keywords"}}

    for keyword, string_data in pairs(keyword_list:get_keywords()) do
        any_keywords = true
        local keyword_line_flow = keyword_table_scroll_pane.add{type="flow", direction="horizontal"}
        keyword_line_flow.add{type="checkbox", state=string_data.enabled, tags={action=toggle_keyword_action, keyword=keyword}, caption=keyword}
        local spacer = keyword_line_flow.add{type="empty-widget"}
        spacer.style.horizontally_stretchable = true

        keyword_line_flow.add{
            type="switch",
            left_label_caption={"tll.keyword_exact_match"},
            left_label_tooltip={"tll.keyword_exact_match_tooltip"},
            right_label_caption={"tll.keyword_substring"},
            right_label_tooltip={"tll.keyword_substring_tooltip"},
            tags={action=constants.actions.set_hidden_keyword_match_type},
        }

        keyword_line_flow.add{
            type="sprite-button",
            tags={action=delete_keyword_action, keyword=keyword},
            sprite="utility/trash",
            style="tool_button_red",
            tooltip={"tll.delete_keyword"}
        }
    end

    if any_keywords then
        no_keywords_label.visible = false
    end

    return textfield_flow[icon_selector_textfield.textfield_name]

end

function Exports.build_exclude_tab(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local exclude_content_frame = player_global.view.exclude_content_frame
    if not exclude_content_frame then return end

    local textfield = build_keyword_tab(
        exclude_content_frame,
        {"tll.add_excluded_keyword"},
        {"tll.add_excluded_keyword_tooltip"},
        constants.actions.exclude_textfield_enter_text,
        constants.actions.exclude_textfield_apply,
        constants.actions.delete_all_excluded_keywords,
        constants.actions.toggle_excluded_keyword,
        constants.actions.delete_excluded_keyword,
        player_global.model.excluded_keywords,
        constants.keyword_lists.exclude
    )
    player_global.view.exclude_textfield = textfield
end


function Exports.build_hide_tab(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local hide_content_frame = player_global.view.hide_content_frame
    if not hide_content_frame then return end

    local textfield = build_keyword_tab(
        hide_content_frame,
        {"tll.add_hidden_keyword"},
        {"tll.add_hidden_keyword_tooltip"},
        constants.actions.hide_textfield_enter_text,
        constants.actions.hide_textfield_apply,
        constants.actions.delete_all_hidden_keywords,
        constants.actions.toggle_hidden_keyword,
        constants.actions.delete_hidden_keyword,
        player_global.model.hidden_keywords,
        constants.keyword_lists.hide
    )
    player_global.view.hide_textfield = textfield
end

return Exports