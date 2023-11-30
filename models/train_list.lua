--- A list of all the LuaTrains in the game at the moment. Updated periodically and on relevant events.

---@class TLLTrainList
---@field trains {[number]: TrainData} Mapping of train ids to LuaTrains

---@class TrainData
---@field train LuaTrain
---@field belongs_to_LTN boolean

---@class TLLTrainList
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

--- Start tracking a train.
---@param train LuaTrain
function TLLTrainList:add(train)
    local belongs_to_LTN = false
    if remote.interfaces["logistic-train-network"] then
        if remote.call("logistic-train-network", "get_next_logistic_stop", train) then
            belongs_to_LTN = true
        end
    end
    if train.valid then
        self.trains[train.id] = {
            train=train,
            belongs_to_LTN=belongs_to_LTN,
        }
    end
end

--- Stop tracking a train.
---@param train LuaTrain
function TLLTrainList:remove_by_LuaTrain(train)
    self.trains[train.id] = nil
end

--- Stop tracking a train.
---@param id number
function TLLTrainList:remove_by_id(id)
    self.trains[id] = nil
end

--- Check every tracked train's .valid attribute and remove falsy trains. Returns true if any trains were removed, false if no trains were removed.
---@return boolean
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
    return #ids_to_remove > 0
end

--- Trash all data about tracked trains and gather data.
function TLLTrainList:initialize()
    self.trains = {}
    for _, surface in pairs(game.surfaces) do
        for _, train in pairs(surface.get_trains()) do
            self:add(train)
        end
    end
end

return TLLTrainList