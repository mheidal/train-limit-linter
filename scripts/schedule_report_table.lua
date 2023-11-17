local constants = require("constants")
local utils = require("utils")

---@class SurfaceTrainScheduleGroups
---@field surface string
---@field train_schedule_groups LuaTrain[][]

---@class ScheduleTableData
---@field limit number
---@field not_set boolean
---@field dynamic boolean
---@field hidden boolean
---@field trains_with_no_schedule_parked table<number, TrainStopAndTrain[]>
---@field train_stops table<string, TrainStopData[]> mapping from backer names to array of data about each train stop with that backer name

---@class TrainStopData
---@field unit_number number
---@field limit number
---@field not_set boolean
---@field dynamic boolean
---@field color Color
---@field proto_name string
---@field excluded boolean

---@class TrainStopAndTrain
---@field train_stop number unit number
---@field train LuaTrain

---@class RailAndTrain
---@field rail LuaEntity
---@field train LuaTrain


local Exports = {}

--- Compares train schedule groups against a new key to see if any of the existing keys are the new key but rotated.
--- For example, this would match "A → B" to "B → A"
---@param key string A train schedule's key
---@param train_schedule_groups table<string, LuaTrain[]> 
---@return string? an equivalent key, if one exists
local function get_equivalent_key(key, train_schedule_groups)
    for existing_key, _ in pairs(train_schedule_groups) do
        if #key == #existing_key then
            superkey = key .. " → " .. key
            if string.find(superkey, existing_key, nil, true) then
                return existing_key
            end
        end
    end
    return nil
end

-- Returns an array of arrays of trains which share a schedule.
---@return SurfaceTrainScheduleGroups
function Exports.get_train_schedule_groups_by_surface()
    local surface_train_schedule_groups = {}

    for _, surface in pairs(game.surfaces) do
        local train_schedule_groups = {}
        local added_schedule = false
        for _, train in pairs(surface.get_trains()) do
            local schedule = train.schedule
            if schedule then
                added_schedule = true
                local key = utils.train_schedule_to_key(schedule)
                local equivalent_key = get_equivalent_key(key, train_schedule_groups)
                if equivalent_key then
                    table.insert(train_schedule_groups[equivalent_key], train)
                else
                    train_schedule_groups[key] = {train}
                end
            end
        end
        if added_schedule then
            table.insert(
                surface_train_schedule_groups,
                {
                    surface = surface,
                    train_schedule_groups = train_schedule_groups
                }
            )
        end
    end
    return surface_train_schedule_groups
end

---@return table<number, RailAndTrain> unit numbers to rails and trains
function Exports.get_rails_to_trains_without_schedule()
    local rails_with_empty_train = {}
    for _, surface in pairs(game.surfaces) do
        for _, train in pairs(surface.get_trains()) do
            if not train.schedule then
                for _, rail in pairs(train.get_rails()) do
                    rails_with_empty_train[rail.unit_number] = {
                        rail=rail,
                        train=train,
                    }
                end
            end
        end
    end
    return rails_with_empty_train
end

---@param train_stop LuaEntity
---@return table<number, LuaEntity> rail unit numbers to rail entities
local function get_rails_near_train_stop(train_stop)
    local rails = {}
    local connected_rail = train_stop.connected_rail
    if connected_rail then
        rails[connected_rail.unit_number] = connected_rail

        local max = 3
        local current_rail = connected_rail
        for _, rail_connection_direction in pairs{
            defines.rail_connection_direction.left,
            defines.rail_connection_direction.right,
            defines.rail_connection_direction.straight,
        } do -- this excludes "none" direction
            for _, rail_direction in pairs(defines.rail_direction) do
                for _ = 1, max do
                    local next_rail = current_rail.get_connected_rail{rail_connection_direction=rail_connection_direction, rail_direction=rail_direction}
                    if next_rail then
                        current_rail = next_rail
                        rails[current_rail.unit_number] = current_rail
                    else
                        break
                    end
                end
            end
        end
    end
    return rails
end

---@param train_schedule_group LuaTrain[]
---@param surface LuaSurface
---@param excluded_keyword_list TLLKeywordList
---@param hidden_keyword_list TLLKeywordList
---@return ScheduleTableData: info about train stops
function Exports.get_train_stop_data(train_schedule_group, surface, excluded_keyword_list, hidden_keyword_list, rails_under_trains_without_schedules)
    ---@type ScheduleTableData
    local ret = {
        limit=0,
        not_set=false,
        dynamic=false,
        hidden=false,
        trains_with_no_schedule_parked = {},
        train_stops = {},
    }
    ---@type TrainSchedule
    local shared_schedule = train_schedule_group[1].schedule

    for _, record in pairs(shared_schedule.records) do
        if not record.temporary then
            if hidden_keyword_list:matches_any(record.station) then
                ret.hidden = true
                return ret
            end

            local station_is_excluded = excluded_keyword_list:matches_any(record.station)

            for _, train_stop in pairs(surface.get_train_stops({name=record.station})) do
                ---@type TrainStopData
                local train_stop_data = {
                    unit_number=train_stop.unit_number,
                    limit=0,
                    not_set=false,
                    dynamic=false,
                    color=train_stop.color,
                    proto_name=train_stop.name,
                    excluded=station_is_excluded,
                }

                if not station_is_excluded then
                    local rails_near_train_stop = get_rails_near_train_stop(train_stop)
                    for rail_unit_number, _ in pairs(rails_near_train_stop) do
                        local rail_and_train = rails_under_trains_without_schedules[rail_unit_number]
                        if rail_and_train then
                            ret.trains_with_no_schedule_parked[rail_and_train.train.id] = {
                                train=rail_and_train.train,
                                train_stop=train_stop.unit_number
                            }
                        end
                    end
    
                    local control_behavior = train_stop.get_control_behavior()
                    ---@diagnostic disable-next-line not sure how to indicate to VS Code that this is LuaTrainStopControlBehavior
                    if control_behavior and control_behavior.set_trains_limit then
                        train_stop_data.dynamic = true
                        ret.dynamic = true
                    end
                    if train_stop.trains_limit == constants.magic_numbers.train_limit_not_set then
                        train_stop_data.not_set = true
                        ret.not_set = true
                    else
                        train_stop_data.limit = train_stop_data.limit + train_stop.trains_limit
                        ret.limit = ret.limit + train_stop.trains_limit
                    end
                end

                ret.train_stops[record.station] = ret.train_stops[record.station] or {}
                table.insert(ret.train_stops[record.station], train_stop_data)
            end
        end
    end
    return ret
end


return Exports