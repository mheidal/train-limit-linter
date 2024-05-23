local constants = require("constants")

local display_tab_view = require("views.display_tab")
local keyword_tabs_view = require("views.keyword_tabs")
local settings_tab_view = require("views.settings_tab")


Exports = {}

-- interface 

---@param player LuaPlayer
function Exports.build_interface(player)
    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    local element_names = constants.gui_element_names.main_interface

    local gui_config = player_global.model.gui_configuration
    if not gui_config.main_interface_open then return end

    if not player_global.view.main_frame then
        local screen_element = player.gui.screen
        main_frame = screen_element.add{type="frame", name="tll_main_frame", direction="vertical"}
        main_frame.style.size = constants.style_data.main_frame_size

        if not gui_config.last_gui_location then
            main_frame.auto_center = true
        else
            main_frame.location = gui_config.last_gui_location
        end

        if not gui_config.main_interface_selected_tab then
            gui_config.main_interface_selected_tab = 1
        end

        player_global.view.main_frame = main_frame

        -- titlebar
        local titlebar_flow = main_frame.add{
            type="flow",
            direction="horizontal",
            name="tll_titlebar_flow",
            style="flib_titlebar_flow"
        }
        titlebar_flow.drag_target = main_frame
        titlebar_flow.add{type="label", style="frame_title", caption={"tll.main_frame_header"}}
        titlebar_flow.add{type="empty-widget", style="flib_titlebar_drag_handle", ignored_by_interaction=true}
        titlebar_flow.add{type="sprite-button", tags={action=constants.actions.close_window}, style="frame_action_button", sprite = "utility/close_white", tooltip={"tll.close"}}

        local tab_pane_frame = main_frame.add{type="frame", style="inside_deep_frame_for_tabs", name=element_names.tabbed_pane_frame}
        local tabbed_pane = tab_pane_frame.add{type="tabbed-pane", style="tabbed_pane_with_no_side_padding", name=element_names.tabbed_pane}

        -- display tab
        local display_tab = tabbed_pane.add{type="tab", caption={"tll.display_tab"}, tags={action=constants.actions.main_interface_switch_tab, tab_index=1}}
        local display_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="tll_tab_content_frame"}
        tabbed_pane.add_tab(display_tab, display_content_frame)
        player_global.view.display_content_frame = display_content_frame

        -- exclude tab
        local exclude_tab = tabbed_pane.add{type="tab", caption={"tll.exclude_tab"}, tags={action=constants.actions.main_interface_switch_tab, tab_index=2}}
        local exclude_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="tll_tab_content_frame"}
        tabbed_pane.add_tab(exclude_tab, exclude_content_frame)
        player_global.view.exclude_content_frame = exclude_content_frame

        -- hide tab
        local hide_tab = tabbed_pane.add{type="tab", caption={"tll.hide_tab"}, tags={action=constants.actions.main_interface_switch_tab, tab_index=3}}
        local hide_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="tll_tab_content_frame"}
        tabbed_pane.add_tab(hide_tab, hide_content_frame)
        player_global.view.hide_content_frame = hide_content_frame

        -- settings tab
        local settings_tab = tabbed_pane.add{type="tab", caption={"tll.settings_tab"}, tags={action=constants.actions.main_interface_switch_tab, tab_index=4}}
        local settings_content_frame = tabbed_pane.add{type="frame", direction="vertical", style="tll_tab_content_frame"}
        tabbed_pane.add_tab(settings_tab, settings_content_frame)
        player_global.view.settings_content_frame = settings_content_frame

    end

    local main_frame = player_global.view.main_frame
    if not main_frame then return end
    local tabbed_pane = main_frame[element_names.tabbed_pane_frame][element_names.tabbed_pane]

    -- tabs
    local tab_index = 1

    if gui_config.main_interface_selected_tab == tab_index then
        tabbed_pane.selected_tab_index = tab_index
        display_tab_view.build_display_tab(player)
    end
    tab_index = tab_index + 1

    if gui_config.main_interface_selected_tab == tab_index then
        tabbed_pane.selected_tab_index = tab_index
        keyword_tabs_view.build_exclude_tab(player)
    end
    tab_index = tab_index + 1

    if gui_config.main_interface_selected_tab == tab_index then
        tabbed_pane.selected_tab_index = tab_index
        keyword_tabs_view.build_hide_tab(player)
    end
    tab_index = tab_index + 1

    if gui_config.main_interface_selected_tab == tab_index then
        tabbed_pane.selected_tab_index = tab_index
        settings_tab_view.build_settings_tab(player)
    end
    tab_index = tab_index + 1

end

return Exports