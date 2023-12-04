local constants = require("constants")

---@alias backer_name string
---@alias unit_number number

---@param train_stop LuaEntity
---@return boolean
local function ltn_stop_is_valid_for_tracking(train_stop)
    return not not (
        train_stop.backer_name
        and train_stop.unit_number
        and (train_stop.prototype.name == "logistic-train-stop" or train_stop.prototype.name == "ltn-port")
    ) -- hi
end

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
    return self
end

---If a train stop name is already tracked, increment its count and add the unit number and entity. If not, begin tracking it.
---@param train_stop LuaEntity
function TLLLTNTrainStopsList:add(train_stop)
    if not train_stop.valid then return end
    if not ltn_stop_is_valid_for_tracking(train_stop) then return end

    script.register_on_entity_destroyed(train_stop)

    if self.train_stops[train_stop.backer_name] then
        local train_stop_group = self.train_stops[train_stop.backer_name]
        train_stop_group.count = train_stop_group.count + 1
        train_stop_group.entities[train_stop.unit_number] = train_stop
    else
        self.train_stops[train_stop.backer_name] = {
            count=1,
            entities={[train_stop.unit_number]=train_stop}
        }
    end
end

---If a train stop's name is already tracked, decrement its count and remove the unit number and entity. If this is the last train stop with that name, stop tracking that name.
---@param train_stop LuaEntity
function TLLLTNTrainStopsList:remove_by_LuaEntity(train_stop)
    if not ltn_stop_is_valid_for_tracking(train_stop) then return end
    self:remove_by_backer_name_and_unit_number(train_stop.backer_name, train_stop.unit_number)
end

---If a train stop's name is already tracked, decrement its count and remove the unit number and entity. If this is the last train stop with that name, stop tracking that name.
---@param backer_name backer_name
---@param unit_number unit_number
function TLLLTNTrainStopsList:remove_by_backer_name_and_unit_number(backer_name, unit_number)
    local train_stop_group = self.train_stops[backer_name]
    if not train_stop_group then return end

    if not train_stop_group.entities[unit_number] then return end

    if train_stop_group.count == 1 then
        self.train_stops[backer_name] = nil
    else
        train_stop_group.count = train_stop_group.count - 1
        train_stop_group.entities[unit_number] = nil
    end
end

---@param unit_number unit_number
function TLLLTNTrainStopsList:remove_by_unit_number(unit_number)
    for backer_name, train_stop_group in pairs(self.train_stops) do
        if train_stop_group.entities[unit_number] then
            if train_stop_group.count == 1 then
                self.train_stops[backer_name] = nil
            else
                train_stop_group.count = train_stop_group.count - 1
                train_stop_group.entities[unit_number] = nil
            end
            break
        end
    end
end

---Gather information about every LTN train stop in the world.
function TLLLTNTrainStopsList:initialize()
    self.train_stops = {}
    if not remote.interfaces[constants.supported_interfaces.logistic_train_network] then return end
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered{name={"logistic-train-stop", "ltn-port"}}) do
            self:add(entity)
        end
    end
end

---Remove invalid train stops
function TLLLTNTrainStopsList:validate()
    local train_stops_to_stop_tracking = {}
    for _, stop_data in pairs(self.train_stops) do
        for _, entity in pairs(stop_data.entities) do
            if not entity.valid then
                train_stops_to_stop_tracking[#train_stops_to_stop_tracking+1] = entity
            end
        end
    end

    for _, train_stop in pairs(train_stops_to_stop_tracking) do
        self:remove_by_LuaEntity(train_stop)
    end
end

---@param train LuaTrain
---@return boolean
function TLLLTNTrainStopsList:train_has_ltn_stop(train)
    if not remote.interfaces[constants.supported_interfaces.logistic_train_network] then
        return false
    end

    if train.schedule then
        for _, record in pairs(train.schedule.records) do
            if record.station and self.train_stops[record.station] then
                return true
            end
        end
    end
    return false
end

return TLLLTNTrainStopsList