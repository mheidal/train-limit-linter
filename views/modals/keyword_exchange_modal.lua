local constants = require("constants")
local modal_content_data = require("models/modal_content_data")

-- This Exports works differently from the rest!
local Exports = {}

---@param player LuaPlayer
---@param parent LuaGuiElement
---@param args table?
---@return TLLModalContentData
Exports[constants.modal_functions.export_keyword_list] = function (player, parent, args)
    if not args then return modal_content_data.TLLModalContentData:new() end
    if not args.keywords then return modal_content_data.TLLModalContentData:new() end

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    local content_frame = parent.add{type="frame", direction="vertical", name="modal_content_frame", style="inside_shallow_frame"}
    content_flow = content_frame.add{type="flow", direction="vertical"}
    content_flow.style.margin = 10


    content_flow.add{type="label", caption={"tll.export_keywords_label"}, tooltip={"tll.export_keywords_tooltip"}}

    local textfield = content_flow.add{type="textfield"}
    textfield.style.width = 300

    local keyword_list
    if args.keywords == constants.keyword_lists.exclude then
        keyword_list = player_global.model.excluded_keywords
    elseif args.keywords == constants.keyword_lists.hide then
        keyword_list = player_global.model.hidden_keywords
    end

    textfield.text = keyword_list:serialize()
    textfield.focus()
    textfield.select(1, #textfield.text)

    local return_data = modal_content_data.TLLModalContentData:new()
    return_data.close_button_visible = true
    return_data.titlebar_visible = true
    return_data.titlebar_caption = {"tll.export_keywords"}

    return return_data
end

---@param player LuaPlayer
---@param parent LuaGuiElement
---@param args table?
---@return TLLModalContentData
Exports[constants.modal_functions.import_keyword_list] = function (player, parent, args)
    if not args then return modal_content_data.TLLModalContentData:new() end
    if not args.keywords then return modal_content_data.TLLModalContentData:new() end

    local content_frame = parent.add{type="frame", direction="vertical", name="modal_content_frame", style="inside_shallow_frame"}

    content_flow = content_frame.add{type="flow", direction="vertical"}
    content_flow.style.margin = 10

    content_flow.add{type="label", caption={"tll.import_keywords_label"}, tooltip={"tll.import_keywords_tooltip"}}

    import_textfield_flow = content_flow.add{type="flow", direction="horizontal"}
    local textfield = import_textfield_flow.add{
        type="textfield",
        name = "textfield",
        tags={
            action=constants.actions.import_keywords_textfield,
            keywords=args.keywords
        },
    }

    textfield.focus()

    import_textfield_flow.add{
        type="sprite-button",
        name="apply_button",
        tags={
            action=constants.actions.import_keywords_button,
            keywords=args.keywords
        },
        style="item_and_count_select_confirm",
        sprite="utility/import",
        tooltip={"tll.import_keywords"},
    }

    local return_data = modal_content_data.TLLModalContentData:new()
    return_data.close_button_visible = true
    return_data.titlebar_visible = true
    return_data.titlebar_caption = {"tll.import_keywords"}

    return return_data
end

return Exports