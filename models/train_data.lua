local utils = require("utils")
local Exports = {}

---@class TLLTrainData
---@field surface string
---@field rolling_stock number[]
---@field schedule string[]
---@field schedule_key string
---@field manual_mode boolean
---@field id number

---@param train LuaTrain
---@return TLLTrainData
local function build_single_train_data(train)

    local rolling_stock_unit_numbers = {}
    for _, carriage in pairs(train.carriages) do
        if carriage.unit_number then
            table.insert(rolling_stock_unit_numbers, carriage.unit_number)
            script.register_on_entity_destroyed(carriage)
        end
    end

    local surface = train.carriages[1].surface.name

    local schedule = {}
    if train.schedule then
        for _, record in pairs(train.schedule.records) do
            table.insert(schedule, record.station)
        end
    end

    local schedule_key = train.schedule and utils.train_schedule_to_key(train.schedule) or ""

    local manual_mode = train.manual_mode

    return {
        surface = surface,
        rolling_stock = rolling_stock_unit_numbers,
        schedule = schedule,
        schedule_key = schedule_key,
        manual_mode = manual_mode,
        id = train.id,
    }
end

---@return table<number, TLLTrainData>
local function build_train_data()
    local train_data = {}
    for _, surface in pairs(game.surfaces) do
        for _, train in pairs(surface.get_trains()) do
            train_data[train.id] = build_single_train_data(train)
        end
    end
    return train_data
end

Exports.build_single_train_data = build_single_train_data
Exports.build_train_data = build_train_data

return Exports