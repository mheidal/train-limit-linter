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

    local content_frame = parent.add{type="flow", direction="vertical", name="modal_content_frame"}

    local textfield = content_frame.add{type="textfield"}
    textfield.style.horizontally_stretchable = true

    local keyword_list
    if args.keywords == constants.keyword_lists.exclude then
        keyword_list = player_global.model.excluded_keywords
    elseif args.keywords == constants.keyword_lists.hide then
        keyword_list = player_global.model.hidden_keywords
    end

    textfield.text = keyword_list:serialize()

    return modal_content_data.TLLModalContentData:new()
end

return Exports