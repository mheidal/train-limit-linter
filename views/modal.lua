local constants = require("constants")

-- if you make a new modal, it should be imported here
local modal_content_frame_imports = {
    require("views.modals.keyword_exchange_modal"),
    require("views.modals.train_stop_name_selector_modal"),
    require("views.modals.remove_train_modal"),
}

local modal_content_frame_functions = {}
for _, import in pairs(modal_content_frame_imports) do
    for function_name, func in pairs(import) do
        modal_content_frame_functions[function_name] = func
    end
end

local Exports = {}

---@param player LuaPlayer
function Exports.build_modal(player)

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    if not player_global.model.modal_open then return end

    local modal_main_frame_name = "tll_modal_main_frame"

    ---@type LuaGuiElement
    local modal_main_frame = player.gui.screen[modal_main_frame_name] or player.gui.screen.add{type="frame", name=modal_main_frame_name, direction="vertical"}
    modal_main_frame.style.size = {0, 0}
    modal_main_frame.style.horizontally_squashable = true
    modal_main_frame.style.vertically_squashable = true
    modal_main_frame.style.horizontally_stretchable = true
    modal_main_frame.style.vertically_stretchable = true

    if not player_global.model.last_modal_location then
        modal_main_frame.auto_center = true
    else
        modal_main_frame.location = player_global.model.last_modal_location
    end

    modal_main_frame.clear()

    player_global.view.modal_main_frame = modal_main_frame
    player.opened = modal_main_frame

    -- titlebar
    local titlebar_flow = modal_main_frame.add{
        type="flow",
        direction="horizontal",
        name="tll_titlebar_flow",
        style="flib_titlebar_flow"
    }
    titlebar_flow.drag_target = modal_main_frame
    local titlebar_caption = titlebar_flow.add{type="label", style="frame_title"}
    titlebar_flow.add{type="empty-widget", style="flib_titlebar_drag_handle", ignored_by_interaction=true}
    local close_button = titlebar_flow.add{type="sprite-button", tags={action=constants.actions.close_modal}, style="frame_action_button", sprite = "utility/close_white", tooltip={"tll.close"}}

    local modal_function_name = player_global.model.modal_function_configuration:get_modal_content_function()
    local modal_args = player_global.model.modal_function_configuration:get_modal_content_args()

    ---@type TLLModalContentData
    local modal_content_data = modal_content_frame_functions[modal_function_name](player, modal_main_frame, modal_args)
    close_button.visible = modal_content_data.close_button_visible
    titlebar_flow.visible = modal_content_data.titlebar_visible
    if modal_content_data.titlebar_caption then titlebar_caption.caption = modal_content_data.titlebar_caption end

end

return Exports