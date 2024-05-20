local constants = require("constants")
local globals = require("scripts.globals")
local modal = require("views.modal")
local main_interface = require("views.main_interface")

local Interfaces = {}

---@param player LuaPlayer
function Interfaces.rebuild_interfaces(player)
    main_interface.build_interface(player)
    modal.build_modal(player)
end

---@param player LuaPlayer
function Interfaces.toggle_interface(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]
    local main_frame = player_global.view.main_frame
    if main_frame == nil then
        player_global.model.main_interface_open = true
        main_interface.build_interface(player)
        player.opened = player_global.view.main_frame
    else
        local modal_main_frame = player_global.view.modal_main_frame
        if modal_main_frame then
            main_frame.ignored_by_interaction = true
        else
            player_global.model.main_interface_open = false
            player_global.model.main_interface_selected_tab = nil
            main_frame.destroy()
            player_global.view = globals.get_empty_player_view()
        end
    end
end

---@param player LuaPlayer
function Interfaces.toggle_modal(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    local main_frame = player_global.view.main_frame
    local modal_main_frame = player_global.view.modal_main_frame

    if modal_main_frame == nil then
        if main_frame ~= nil then
            local dimmer = player.gui.screen.add{
                type="frame",
                style="tll_frame_semitransparent",
                tags={action=constants.actions.focus_modal}
            }
            dimmer.style.size = constants.style_data.main_frame_size
            dimmer.location = main_frame.location
            player_global.view.main_frame_dimmer = dimmer
        end
        player_global.model.modal_open = true

        modal.pre_build_cleanup(player)
        modal.build_modal(player)
    else
        player_global.model.modal_open = false
        modal_main_frame.destroy()
        if player_global.view.main_frame_dimmer ~= nil then
            player_global.view.main_frame_dimmer.destroy()
            player_global.view.main_frame_dimmer = nil
        end
        player_global.view.modal_main_frame = nil
        if main_frame then
            player.opened = main_frame
            main_frame.ignored_by_interaction = false
        end
    end
end

return Interfaces