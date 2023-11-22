local constants = require("constants")
local utils = require("utils")

---@class ScheduleTableData
---@field limit number
---@field not_set boolean
---@field dynamic boolean
---@field hidden boolean
---@field trains_with_no_schedule_parked table<number, TrainStopAndTrain[]>
---@field train_stops table<string, TrainStopData[]> mapping from backer names to array of data about each train stop with that backer name

---@class TrainGroup
---@field surface string
---@field filtered_schedule {key: string, records: TrainScheduleRecord[]}
---@field all_schedules table<string, TrainScheduleRecord[]>
---@field trains number[] ids of the trains in this group

---@class TrainStopData
---@field unit_number number
---@field limit number
---@field not_set boolean
---@field dynamic boolean
---@field color Color
---@field proto_name string

---@class TrainStopAndTrain
---@field train_stop number unit number
---@field train LuaTrain

---@class RailAndTrain
---@field rail LuaEntity
---@field train LuaTrain

local Exports = {}

---@param records TrainSchedule
---@param excluded_keywords TLLKeywordList
---@return TrainScheduleRecord[]
local function get_filtered_schedule(records, excluded_keywords)
    local filtered_schedule = {}
    for _, record in pairs(records) do
        if not record.temporary and record.station then
            if not excluded_keywords:matches_any(record.station) then
                filtered_schedule[#filtered_schedule+1] = record
            end
        end
    end
    return filtered_schedule
end

---@param excluded_keywords TLLKeywordList
---@param hidden_keywords TLLKeywordList
---@return table<string, TrainGroup>
function Exports.get_train_groups(excluded_keywords, hidden_keywords)
    ---@type table<string, TrainGroup>
    local train_groups = {}

    for surface_name, surface in pairs(game.surfaces) do
        for _, train in pairs(surface.get_trains()) do

            if train.schedule then
                for _, record in pairs(train.schedule.records) do
                    if record.station and hidden_keywords:matches_any(record.station) then
                        goto continue_schedule
                    end
                end

                local filtered_records = get_filtered_schedule(train.schedule.records, excluded_keywords)
                local filtered_key = utils.train_records_to_key(filtered_records)
                local train_group = utils.get_or_insert(train_groups, filtered_key, {
                    surface=surface_name,
                    filtered_schedule={
                        key=filtered_key,
                        records=deep_copy(filtered_records)
                    },
                    all_schedules={},
                    trains={},
                })
                table.insert(train_group.trains, train.id)
                local full_key = utils.train_records_to_key(train.schedule.records)
                if not train_group.all_schedules[full_key] then
                    train_group.all_schedules[full_key] = train.schedule.records
                end
            end
            ::continue_schedule::
        end
    end

    return train_groups
end

---@param train_groups TrainGroup[]
---@return table<string, TrainGroup[]>
function Exports.group_train_groups_by_surface(train_groups)
    local surface_train_groups = {}
    for _, train_group in pairs(train_groups) do
        local surface_train_group = utils.get_or_insert(surface_train_groups, train_group.surface, {})
        table.insert(surface_train_group, train_group)
    end
    return surface_train_groups
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

---@param train_group TrainGroup
---@param surface string
---@return ScheduleTableData: info about train stops
function Exports.get_train_stop_data(train_group, surface, rails_under_trains_without_schedules)
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
    local filtered_records = train_group.filtered_schedule.records

    for _, record in pairs(filtered_records) do
        if not record.temporary and record.station then

            for _, train_stop in pairs(game.surfaces[surface].get_train_stops({name=record.station})) do
                ---@type TrainStopData
                local train_stop_data = {
                    unit_number=train_stop.unit_number,
                    limit=0,
                    not_set=false,
                    dynamic=false,
                    color=train_stop.color,
                    proto_name=train_stop.name,
                }

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

                ret.train_stops[record.station] = ret.train_stops[record.station] or {}
                table.insert(ret.train_stops[record.station], train_stop_data)
            end
        end
    end
    return ret
end


---@param table_config TLLScheduleTableConfiguration
---@param schedule TrainScheduleRecord[]
---@param schedule_report_data ScheduleTableData
---@param excluded_keywords TLLKeywordList
---@param opinionate boolean
---@param nonexistent_stations_in_schedule table<string, boolean>
---@return LocalisedString
function Exports.generate_schedule_caption(table_config, schedule, schedule_report_data, excluded_keywords, opinionate, nonexistent_stations_in_schedule)

    local schedule_caption
    for _, record in pairs(schedule) do
        local stop_name = record.station or {"tll.temporary", record.rail.position.x, record.rail.position.y}
        local stop_excluded = not record.station or excluded_keywords:matches_any(stop_name --[[@as string]])

        if not schedule_caption then
            schedule_caption = {"", stop_excluded and "[" or "", stop_name}
        else
            schedule_caption = {"", schedule_caption, stop_excluded and " [" or "", " → ",  stop_name}
        end

        if record.station then
            if table_config.show_train_limits_separately and not stop_excluded then
                local train_group_limit = 0
                if schedule_report_data.train_stops[record.station] then
                    for _, train_stop_data in pairs(schedule_report_data.train_stops[record.station]) do
                        train_group_limit = train_group_limit + train_stop_data.limit
                    end
                end
                schedule_caption = {"", schedule_caption, " (" .. train_group_limit .. ")"}
            end
            if opinionate and nonexistent_stations_in_schedule[record.station] then
                schedule_caption = {"", schedule_caption, {"tll.warning_icon"}}
            end
        end

        schedule_caption = {"", schedule_caption, stop_excluded and "]" or ""}

    end
    return schedule_caption
end

return Exports