local constants = require("constants")
local TLLModalContentData = require("models.modal_content_data")

-- This Exports works differently from the rest!
local Exports = {}

---@param player LuaPlayer
---@param parent LuaGuiElement
---@param args table?
---@return TLLModalContentData
Exports[constants.modal_functions.train_stop_name_selector] = function (player, parent, args)
    parent.clear()
    local return_data =  TLLModalContentData.new()
    return_data:set_titlebar_caption{"tll.train_stop_name_selector_titlebar_caption"}
    return_data:set_close_button_visible(true)

    if not args then return return_data end
    if not args.keywords then return return_data end

    local content_flow = parent.add{type="flow", direction="vertical"}
    content_flow.style.margin = 10
    content_flow.style.horizontally_stretchable = true
    content_flow.style.minimal_width = 300

    local train_stop_name_to_count = {}
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered{name="train-stop"}) do
            local name = entity.backer_name
            if name then
                if train_stop_name_to_count[name] then
                    train_stop_name_to_count[name] = train_stop_name_to_count[name] + 1
                else
                    train_stop_name_to_count[name] = 1
                end
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
    local button_height = 28
    local space_height = 4
    local button_shown_count = 20
    name_table_pane.style.maximal_height = (button_shown_count * button_height) + ((button_shown_count - 1) * space_height)

    for _, datum in pairs(train_stop_data) do
        local button = name_table_pane.add{
            type="button",
            style="list_box_item",
            tags={
                action=constants.actions.train_stop_name_selector_select_name,
                train_stop_name=datum.name,
                keywords=args.keywords
            }
        }
        if datum.count > 1 then
            button.caption={"tll.train_stop_name_and_count", datum.name, datum.count}
        else
            button.caption=datum.name
        end
        button.style.width = 0
        button.style.horizontally_stretchable = true
        button.style.maximal_width = 332 -- taken from O-menu
    end

    return return_data
end

return Exports