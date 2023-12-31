local constants = require("constants")
local globals = require("scripts.globals")
local TLLModalContentData = require("models.modal_content_data")

-- This Exports works differently from the rest!
local Exports = {}

---@param player LuaPlayer
---@param parent LuaGuiElement
---@param args table?
---@return TLLModalContentData
Exports[constants.modal_functions.export_keyword_list] = function (player, parent, args)
    parent.clear()
    local return_data = TLLModalContentData.new()
    return_data.close_button_visible = true
    return_data.titlebar_visible = true
    return_data.titlebar_caption = {"tll.export_keywords"}
    if not args then return return_data end
    if not args.keywords then return return_data end

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    content_flow = parent.add{type="flow", direction="vertical"}
    content_flow.style.margin = 10


    content_flow.add{type="label", caption={"tll.export_keywords_label"}, tooltip={"tll.export_keywords_tooltip"}}

    local textfield = content_flow.add{type="textfield"}
    textfield.style.width = 300

    local keyword_list = globals.get_keyword_list_from_name(player_global, args.keywords)

    textfield.text = keyword_list:serialize()
    textfield.focus()
    textfield.select(1, #textfield.text)

    return return_data
end

---@param player LuaPlayer
---@param parent LuaGuiElement
---@param args table?
---@return TLLModalContentData
Exports[constants.modal_functions.import_keyword_list] = function (player, parent, args)
    parent.clear()
    local return_data = TLLModalContentData.new()
    return_data:set_close_button_visible(true)
    return_data:set_titlebar_visible(true)
    return_data:set_titlebar_caption{"tll.import_keywords"}
    if not args then return return_data end
    if not args.keywords then return return_data end

    content_flow = parent.add{type="flow", direction="vertical"}
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
    return return_data
end

return Exports