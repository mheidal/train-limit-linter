local constants = require("constants")

local Exports = {}


---@param train_id number
---@param player LuaPlayer
function Exports.mark_train_for_deconstruction(train_id, player)
    player.print("I should have marked a train for deconstruction with id " .. train_id)
    return
end

---@param train_id number
---@param player LuaPlayer
function Exports.delete_train(train_id, player)
    player.print("I should have deleted a train with id " .. train_id)
end

function Exports.repath_train(train_id, player)
    player.print("I should have repathed a train with id " .. train_id)
end

return Exports