--- A list of all the LuaTrains in the game at the moment. Updated periodically and on relevant events.

---@class TLLTrainList
---@field trains {[number]: TrainData} Mapping of train ids to LuaTrains
---@field add fun(self: TLLTrainList, train: LuaTrain)
---@field remove_by_LuaTrain fun(self: TLLTrainList, train: LuaTrain)
---@field remove_by_id fun(self: TLLTrainList, id: number)
---@field validate fun(self: TLLTrainList) Check every tracked train's .valid attribute and remove falsy trains
---@field initialize fun(self: TLLTrainList) Trash all data and rebuild the list of trains

---@class TrainData -- mostly empty class right now, can be modified later for stuff like tracking if a train belongs to LTN
---@field train LuaTrain

local TLLTrainList = {}
local mt = { __index = TLLTrainList }
script.register_metatable("TLLTrainList", mt)

function TLLTrainList.new()
    local self = {
        trains={},
    }
    setmetatable(self, mt)

    self:initialize()

    return self
end

---@param train LuaTrain
function TLLTrainList:add(train)
    if train.valid then
        self.trains[train.id] = {
            train=train,
        }
    end
end

---@param train LuaTrain
function TLLTrainList:remove_by_LuaTrain(train)
    self.trains[train.id] = nil
end

---@param id number
function TLLTrainList:remove_by_id(id)
    self.trains[id] = nil
end

function TLLTrainList:validate()
    local ids_to_remove = {}
    for id, train_data in pairs(self.trains) do
        if not train_data.train.valid then
            ids_to_remove[#ids_to_remove+1] = id
        end
    end
    for _, id in pairs(ids_to_remove) do
        self:remove_by_id(id)
    end
end

function TLLTrainList:initialize()
    self.trains = {}
    for _, surface in pairs(game.surfaces) do
        for _, train in pairs(surface.get_trains()) do
            if train.valid then
                self:add(train)
            end
        end
    end
end

return TLLTrainList