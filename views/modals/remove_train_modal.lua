local constants = require("constants")
local globals = require("scripts.globals")
local TLLModalContentData = require("models.modal_content_data")
local train_removal_buttons = require("views.train_removal_radio_buttons")

-- This Exports works differently from the rest!
local Exports = {}

---@param player LuaPlayer
---@param parent LuaGuiElement
---@param args table?
---@return TLLModalContentData
Exports[constants.modal_functions.remove_trains] = function (player, parent, args)
    local return_data = TLLModalContentData.new()
    return_data.close_button_visible = true
    return_data.titlebar_visible = true
    return_data.titlebar_caption = "Remove trains" -- todo locale
    if not args then return return_data end
    if not args.train_ids then return return_data end

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    local content_frame = parent.add{type="frame", direction="vertical", name="modal_content_frame", style="inside_shallow_frame"}
    header_flow = content_frame.add{type="flow", direction="horizontal"}
    header_flow.style.margin = 10

    local radio_button_flow = header_flow.add{type="flow", direction="vertical"}

    train_removal_buttons.add_train_removal_radio_buttons(radio_button_flow, player_global.model.general_configuration)

    header_flow.add{type="sprite-button", style="tool_button_red", sprite="utility/trash", tags={action=constants.actions.remove_trains}}

    local scroll_pane = content_frame.add{type="scroll-pane", scroll_policy="auto-and-reserve-space"}
    scroll_pane.style.maximal_height = 650
    local trains_table = scroll_pane.add{type="table", column_count=3, style="trains_table"}
    for _, train_id in pairs(args.train_ids) do
        local train = game.get_train_by_id(train_id)
        if train then
            local train_flow = trains_table
                .add{type="frame", direction="vertical"}
                .add{type="flow", direction="vertical"}
            local minimap = train_flow
                .add{type="button", style="locomotive_minimap_button"}
                .add{type="minimap"}
            minimap.entity = train.front_stock
            train_flow.add{
                type="checkbox",
                state=not not player_global.model.trains_to_remove_list.trains_to_remove[train_id], -- hi (coerce to boolean)
                caption="Remove train",
                tags={action=constants.actions.toggle_train_to_remove, train_id=train_id}
            }
        end
    end

    return return_data
end

return Exports