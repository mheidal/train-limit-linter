local constants = require("constants")

---@alias backer_name string
---@alias unit_number number

---@class TLLLTNTrainStopsList
---@field train_stops {[backer_name]: {count: number, entities: {[unit_number]: LuaEntity}}}
local TLLLTNTrainStopsList = {}

local mt = { __index = TLLLTNTrainStopsList }
script.register_metatable("TLLLTNTrainStopsList", mt)

function TLLLTNTrainStopsList.new()
    local self = {
        train_stops={},
    }
    setmetatable(self, mt)
    self:initialize()
    return self
end

---If a train stop name is already tracked, increment its count. If not, begin tracking it.
---@param train_stop LuaEntity
function TLLLTNTrainStopsList:add(train_stop)
    ---@todo

end

---If a train stop name is already tracked, decrement its count. If not, stop tracking it.
---@param train_stop LuaEntity
function TLLLTNTrainStopsList:remove(train_stop)
    ---@todo

end

---Gather information about every LTN train stop in the world.
function TLLLTNTrainStopsList:initialize()
    if not remote.interfaces[constants.supported_interfaces.logistic_train_network] then return end
    ---@todo

end

---Remove invalid train stops
function TLLLTNTrainStopsList:validate()
    ---@todo

end

return TLLLTNTrainStopsList