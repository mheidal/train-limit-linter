local constants = require("constants")

-- if you make a new modal, it should be imported here
local modal_content_frame_imports = {
    require("views.modals.keyword_exchange_modal"),
}

local modal_content_frame_functions = {}
for _, import in pairs(modal_content_frame_imports) do
    for function_name, func in pairs(import) do
        modal_content_frame_functions[function_name] = func
    end
end

local Exports = {}

---@param player LuaPlayer
---@param modal_function string -- must be a value in constants.modal_functions
---@param args table? -- arguments for the modal function
function Exports.build_modal(player,modal_function, args)

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    ---@type LuaGuiElement
    local modal_main_frame = player.gui.screen.add{type="frame", name="tll_modal_main_frame", direction="vertical"}
    modal_main_frame.style.size = {0, 0}
    modal_main_frame.style.horizontally_squashable = true
    modal_main_frame.style.vertically_squashable = true
    modal_main_frame.style.horizontally_stretchable = true
    modal_main_frame.style.vertically_stretchable = true

    modal_main_frame.auto_center = true

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

    ---@type TLLModalContentData
    local modal_content_data = modal_content_frame_functions[modal_function](player, modal_main_frame, args)
    close_button.visible = modal_content_data.close_button_visible
    titlebar_flow.visible = modal_content_data.titlebar_visible
    if modal_content_data.titlebar_caption then titlebar_caption.caption = modal_content_data.titlebar_caption end

end

---@param player LuaPlayer
---@param modal_function string?
---@param args table?
function Exports.toggle_modal(player, modal_function, args)

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local modal_main_frame = player_global.view.modal_main_frame
    if modal_main_frame == nil then
        if not modal_function then return end
        Exports.build_modal(player, modal_function, args)
    else
        modal_main_frame.destroy()
        player_global.view.modal_main_frame = nil
        local main_frame = player_global.view.main_frame
        if main_frame then
            player.opened = main_frame
            main_frame.ignored_by_interaction = false
        end
    end

end

return Exports