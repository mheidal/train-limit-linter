local constants = require("constants")
local utils = require("utils")
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
    return_data.titlebar_caption = {"tll.remove_trains_header"}
    if not args then return return_data end
    if not args.train_ids then return return_data end

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    local element_names = constants.gui_element_names.remove_train_modal

    local content_frame
    if parent[element_names.modal] then
        content_frame = parent[element_names.modal]
    else
        content_frame = parent.add{
            type="frame",
            direction="vertical",
            name=element_names.modal,
            style="inside_shallow_frame"
        }
    end

    header_flow = content_frame[element_names.header_flow] or content_frame.add{
        type="flow",
        name=element_names.header_flow,
        direction="vertical"
    }
    header_flow.clear()
    header_flow.style.margin = 10
    train_removal_buttons.add_train_removal_radio_buttons(header_flow, player_global.model.general_configuration)

    local scroll_pane_frame = content_frame[element_names.scroll_pane_frame] or content_frame.add{
        type="frame",
        name=element_names.scroll_pane_frame,
        direction="vertical",
        style="deep_frame_in_shallow_frame"
    }

    local scroll_pane = scroll_pane_frame[element_names.scroll_pane] or scroll_pane_frame.add{
        type="scroll-pane",
        name=element_names.scroll_pane,
        scroll_policy="auto-and-reserve-space"
    }
    scroll_pane.clear()
    scroll_pane.style.maximal_height = 650
    local trains_table = scroll_pane.add{type="table", column_count=3, style="trains_table"}

    trains_table.style.width = 852

    for _, train_id in pairs(args.train_ids) do
        local train = game.get_train_by_id(train_id)
        if train and train.valid then
            local status_field = (
                train.manual_mode and {"tll.manually_stopped"}
                or ((train.state == defines.train_state.on_the_path or train.state == defines.train_state.arrive_signal or train.state == defines.train_state.wait_signal or train.state == defines.train_state.arrive_station)
                    and train.path_end_stop and {"tll.heading_to_station", train.path_end_stop.backer_name}
                    or train.path_end_rail and {"tll.heading_to_rail", train.path_end_rail.position.x, train.path_end_rail.position.y, train.path_end_rail.surface.name})
                or (train.state == defines.train_state.no_path
                    and train.schedule.records[train.schedule.current].station and {"tll.no_path_to_station", train.schedule.records[train.schedule.current].station}
                    or train.schedule.records[train.schedule.current].rail and {"tll.no_path_to_rail", train.schedule.records[train.schedule.current].rail.position.x, train.schedule.records[train.schedule.current].rail.position.y, train.schedule.records[train.schedule.current].rail.surface.name})
                    or (train.state == defines.train_state.wait_station and {"tll.waiting_at_station", train.station.backer_name})
                    or (train.state == defines.train_state.destination_full and {"tll.destination_full"})
                or "Unexpected train state"
            )

            local train_cargo = train.get_contents()
            local cargo_stack_count = 0
            local cargo_count = 0
            for item_name, item_count in pairs(train_cargo) do
                cargo_count = cargo_count + item_count
                cargo_stack_count = cargo_stack_count + math.floor(item_count / game.item_prototypes[item_name].stack_size)
            end
            local train_fluid_content = train.get_fluid_contents()
            local total_fluid_count = 0
            for _, fluid_count in pairs(train_fluid_content) do
                total_fluid_count = total_fluid_count + fluid_count
            end

            local cargo_present = cargo_count ~= 0
            local fluids_present = total_fluid_count ~= 0

            local cargo_field = {
                "",
                cargo_present and {"tll.cargo", utils.localize_to_metric(cargo_count, "", 1), utils.localize_to_metric(cargo_stack_count, "", 1)} or "",
                cargo_present and fluids_present and "\n" or "",
                fluids_present and {"tll.fluids", utils.localize_to_metric(total_fluid_count, "", 1)} or "",
                not (cargo_present or fluids_present) and {"tll.no_contents"} or "",
            }

            local description = {
                "",
                {"tll.train_status", status_field},
                "\n",
                cargo_field,
            }

            local train_flow = trains_table
                .add{type="frame", direction="vertical"}
                .add{type="flow", direction="vertical"}
            train_flow.style.vertically_stretchable = true
            local minimap = train_flow
                .add{type="frame", style="deep_frame_in_shallow_frame"}
                .add{type="minimap", zoom=1.5}
            minimap.entity = train.front_stock

            minimap.add{
                type="button",
                tooltip={"tll.open_train"},
                tags={action=constants.actions.open_train, train_id=train_id},
                style="tll_remove_train_minimap_button",
            }

            local description_label = train_flow.add{type="label", caption=description}
            description_label.style.single_line = false
            description_label.style.maximal_width = 256

            train_flow.add{
                type="checkbox",
                name=constants.gui_element_names.train_removal_modal.checkbox,
                state=not not player_global.model.trains_to_remove_list:get_trains_to_remove()[train_id], -- hi (coerce to boolean)
                caption={"tll.remove_train"},
                tags={action=constants.actions.toggle_train_to_remove_checkbox, train_id=train_id}
            }
        end
    end

    local footer_frame = content_frame[element_names.footer_frame] or content_frame.add{
        type="frame",
        name=element_names.footer_frame,
        direction="horizontal"
    }
    footer_frame.clear()
    footer_frame.add{type="empty-widget", style="tll_spacer"}
    footer_frame.add{type="button", style="red_confirm_button", caption={"tll.remove_trains_header"}, tags={action=constants.actions.remove_trains}}

    return return_data
end

return Exports