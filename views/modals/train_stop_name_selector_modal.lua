local constants = require("constants")
local modal_content_data = require("models/modal_content_data")
local icon_selector_textfield = require("views/icon_selector_textfield")

-- This Exports works differently from the rest!
local Exports = {}

---@param player LuaPlayer
---@param parent LuaGuiElement
---@param args table?
---@return TLLModalContentData
Exports[constants.modal_functions.train_stop_name_selector] = function (player, parent, args)

    local content_frame = parent.add{type="frame", direction="vertical", name="modal_content_frame", style="inside_shallow_frame"}
    local content_flow = content_frame.add{type="flow", direction="vertical"}
    content_flow.style.margin = 10
    local search_bar = content_flow.add{type="flow", direction="horizontal"}
    local spacer = search_bar.add{type="empty-widget"}
    spacer.style.horizontally_stretchable = true
    local textfield_frame = search_bar.add{type="frame", direction="horizontal", style="search_popup_frame"}
    icon_selector_textfield.build_icon_selector_textfield(textfield_frame, {action=constants.actions.train_stop_name_selector_search})

    local search_button = search_bar.add{
        type="sprite-button",
        tags={
            action=constants.actions.open_modal,
        },
        style="tool_button",
        sprite="utility/search_icon",
    }
    -- todo: toggle search frame

    local train_stop_name_to_count = {}
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered{name="train-stop"}) do
            local name = entity.backer_name
            if train_stop_name_to_count[name] then
                train_stop_name_to_count[name] = train_stop_name_to_count[name] + 1
            else
                train_stop_name_to_count[name] = 1
            end
        end
    end

    local sorted_train_stop_names = {}
    for stop_name, _ in pairs(train_stop_name_to_count) do table.insert(sorted_train_stop_names, stop_name) end
    table.sort(sorted_train_stop_names)

    local train_stop_data = {}
    for _, stop_name in pairs(sorted_train_stop_names) do
        table.insert(train_stop_data, {name=stop_name, count=train_stop_name_to_count[stop_name]})
    end

    local name_table_pane_frame = content_flow.add{type="frame", direction="vertical", style="deep_frame_in_shallow_frame"}
    local name_table_pane = name_table_pane_frame.add{type="scroll-pane", direction="vertical"} -- size stuff
    for _, datum in pairs(train_stop_data) do
        local button = name_table_pane.add{type="button", style="list_box_item"}
        if datum.count > 1 then
            button.caption={"tll.train_stop_name_and_count", datum.name, datum.count}
        else
            button.caption=datum.name
        end
        button.style.width = 0
        button.style.horizontally_stretchable = true
        button.style.maximal_width = 332 -- taken from O-menu
    end

    local return_data =  modal_content_data.TLLModalContentData:new()
    return_data.titlebar_caption = {"tll.train_stop_name_selector_titlebar_caption"}
    return_data.close_button_visible = true

    return return_data
end

return Exports