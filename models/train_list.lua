--- A list of all the LuaTrains in the game at the moment. Updated periodically and on relevant events.

---@class TrainList
---@field trains {[number]: TrainData} Mapping of train ids to LuaTrains
---@field add fun(self: TrainList, train: LuaTrain)
---@field remove fun(self: TrainList, train: LuaTrain)
---@field validate fun(self: TrainList) Check every tracked train's .valid attribute and remove falsy trains
---@field initialize fun(self: TrainList) Trash all data and rebuild the list of trains

---@class TrainData -- mostly empty class right now, can be modified later for stuff like tracking if a train belongs to LTN
---@field train LuaTrain

local TrainList = {}
local mt = { __index = TrainList }
script.register_metatable("TrainList", mt)

function TrainList.new()
    local self = {
        trains={},
    }
    setmetatable(self, mt)
    return self
end

---@param train LuaTrain
function TrainList:add(train)
    if train.valid then
        self.trains[train.id] = {
            train=train,
        }
    end

end

---@param train LuaTrain
function TrainList:remove(train)
    self.trains[train.id] = nil
end

function TrainList:validate()
    local keys_to_remove = {}
    for id, train_data in pairs(self.trains) do
        if not train_data.train.valid then
            keys_to_remove[#keys_to_remove+1] = id
        end
    end
    for _, key in pairs(keys_to_remove) do
        self.trains[key] = nil
    end
end

return TrainList