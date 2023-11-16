local constants = require("constants")

local Exports = {}


---@param train_id number
---@param player LuaPlayer
function Exports.mark_train_for_deconstruction(train_id, player)
    local train = game.get_train_by_id(train_id)
    if not train then return end
    local warning_message = {"Deconstructing a train at [gps=__1__,__2__]", train.front_stock.position.x,train.front_stock.position.y} -- todo
    player.print(warning_message)
    for _, carriage in pairs(train.carriages) do
        carriage.order_deconstruction(player.force, player)
    end
end

---@param train_id number
---@param player LuaPlayer
function Exports.delete_train(train_id, player)
    local train = game.get_train_by_id(train_id)
    if not train then return end
    local warning_message = {"Deleting a train at [gps=__1__,__2__]", train.front_stock.position.x,train.front_stock.position.y} -- todo
    player.print(warning_message)
    for _, carriage in pairs(train.carriages) do
        carriage.destroy{raise_destroy=true}
    end
end

function Exports.repath_train(train_id, player)
    player.print("I should have repathed a train with id " .. train_id)
end

return Exports