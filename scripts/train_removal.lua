local constants = require("constants")

local Exports = {}


---@param train_id number
---@param player LuaPlayer
function Exports.mark_train_for_deconstruction(train_id, player)
    local train = game.get_train_by_id(train_id)
    if not train then return end
    player.print{"tll.deconstructing_train", train.front_stock.position.x, train.front_stock.position.y, train.front_stock.surface.name}
    for _, carriage in pairs(train.carriages) do
        carriage.order_deconstruction(player.force, player)
    end
end

---@param train_id number
---@param player LuaPlayer
function Exports.delete_train(train_id, player)
    local train = game.get_train_by_id(train_id)
    if not train then return end
    player.print{"tll.deleting_train", train.front_stock.position.x, train.front_stock.position.y, train.front_stock.surface.name}
    for _, carriage in pairs(train.carriages) do
        carriage.destroy{raise_destroy=true}
    end
end

return Exports