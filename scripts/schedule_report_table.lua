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
---@field all_schedules table<string, AllSchedulesEntry>
---@field trains number[] ids of the trains in this group

---@alias AllSchedulesEntry {records: TrainScheduleRecord[], count: number}

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

---@param records TrainScheduleRecord[]
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

---@param existing_train_groups table<string, TrainGroup>
---@param key string
---@return string
local function get_equivalent_key(existing_train_groups, key)
    local existing_keys = {}
    for existing_key, _ in pairs(existing_train_groups) do
        existing_keys[#existing_keys+1] = existing_key
    end
    local equivalent_key = key
    for _, existing_key in pairs(existing_keys) do
        if #key == #existing_key then
            local superkey = existing_key .. " → " .. existing_key
            if string.find(superkey, key, nil, true) then
                return existing_key
            end
        end
    end
    return equivalent_key
end

---@param excluded_keywords TLLKeywordList
---@param hidden_keywords TLLKeywordList
---@return table<string, table<string, TrainGroup>> {<surface name>: {<filtered key>: TrainGroup}}
function Exports.get_surfaces_to_train_groups(excluded_keywords, hidden_keywords)
    ---@type table<string, TrainGroup>
    local surfaces_to_train_groups = {}

    for surface_name, surface in pairs(game.surfaces) do
        local train_groups_on_surface = {}
        local any_train_groups_on_surface = false
        for _, train in pairs(surface.get_trains()) do
            local train_has_locomotive = false
            for _, carriage in pairs(train.carriages) do
                if carriage.type == "locomotive" then
                    train_has_locomotive = true
                end
            end

            if train.schedule and train_has_locomotive then
                for _, record in pairs(train.schedule.records) do
                    if record.station and hidden_keywords:matches_any(record.station) then
                        goto continue_schedule
                    end
                end
                any_train_groups_on_surface = true

                local filtered_records = get_filtered_schedule(train.schedule.records, excluded_keywords)
                local filtered_key = utils.train_records_to_key(filtered_records)
                local equivalent_key = get_equivalent_key(train_groups_on_surface, filtered_key)

                ---@type TrainGroup
                local train_group = utils.get_or_insert(train_groups_on_surface, equivalent_key, {
                    filtered_schedule={
                        key=equivalent_key,
                        records=deep_copy(filtered_records)
                    },
                    all_schedules={},
                    trains={},
                })
                table.insert(train_group.trains, train.id)
                local full_key = utils.train_records_to_key(train.schedule.records)
                local all_schedules_entry = utils.get_or_insert(train_group.all_schedules, full_key, {records=train.schedule.records, count=0})
                all_schedules_entry.count = all_schedules_entry.count + 1
            end
            ::continue_schedule::
        end

        if any_train_groups_on_surface then
            surfaces_to_train_groups[surface_name] = train_groups_on_surface
        end
    end

    return surfaces_to_train_groups
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
---@param records TrainScheduleRecord[]
---@param schedule_report_data ScheduleTableData
---@param excluded_keywords TLLKeywordList
---@param opinionate boolean
---@param nonexistent_stations_in_schedule table<string, boolean>
---@param non_excluded_label_color LocalisedString
---@return LocalisedString
function Exports.generate_schedule_caption(
    table_config,
    records,
    schedule_report_data,
    excluded_keywords,
    opinionate,
    nonexistent_stations_in_schedule,
    non_excluded_label_color
)

    ---@type {stop_name: LocalisedString, color: LocalisedString, excluded: boolean}[][]
    local stop_group_list = {}

    for _, record in pairs(records) do

        ---@type LocalisedString
        local stop_name = (
        record.temporary and (record.rail and {"tll.temporary", record.rail.position.x, record.rail.position.y} or {"tll.invalid_schedule"})) or {"", record.station}

        local excluded = not not (record.temporary or record.station and excluded_keywords:matches_any(record.station)) -- hi
        if record.station then
            if table_config.show_train_limits_separately and not excluded then
                local train_group_limit = 0
                if schedule_report_data.train_stops[record.station] then
                    for _, train_stop_data in pairs(schedule_report_data.train_stops[record.station]) do
                        train_group_limit = train_group_limit + train_stop_data.limit
                    end
                end
                stop_name[#stop_name+1] = " (" .. train_group_limit .. ")"
            end
            if opinionate and nonexistent_stations_in_schedule[record.station] then
                stop_name[#stop_name+1] = {"tll.warning_icon"}
            end
        end
        local stop_data = {
            stop_name=stop_name,
            excluded=excluded
        }

        local current_stop_list = stop_group_list[#stop_group_list]
        if current_stop_list and excluded == current_stop_list[1].excluded then
            current_stop_list[#current_stop_list+1] = stop_data
        else
            stop_group_list[#stop_group_list+1] = {stop_data}
        end
    end

    ---@type LocalisedString
    local schedule_caption = {""}

    local first_stop_in_schedule = true

    for _, stop_group in pairs(stop_group_list) do
        if stop_group[1] then

            local first_stop_in_group = true

            ---@type LocalisedString
            stop_group_localised_string = {"tll.color_text"}
            if stop_group[1].excluded then
                stop_group_localised_string[#stop_group_localised_string+1] = {"tll.gray"}
            else
                stop_group_localised_string[#stop_group_localised_string+1] = non_excluded_label_color
            end

            ---@type LocalisedString
            local stop_names = {""}
            for _, stop in pairs(stop_group) do

                ---@type LocalisedString
                local stop_name = {""}

                if first_stop_in_group then
                    first_stop_in_group = false
                    if stop.excluded then
                        stop_name[#stop_name+1] = " ["
                    end
                end

                if not first_stop_in_schedule then
                    stop_name[#stop_name+1] = {"", " → ", stop.stop_name}
                else
                    first_stop_in_schedule = false
                    stop_name[#stop_name+1] = stop.stop_name
                end
                stop_names[#stop_names+1] = stop_name
            end

            if stop_group[1].excluded then
                stop_names[#stop_names+1] = " ]"
            end
            stop_group_localised_string[#stop_group_localised_string+1] = stop_names
            schedule_caption[#schedule_caption+1] = stop_group_localised_string
        end
    end

    return schedule_caption
end

---@generic T
---@param all_schedules AllSchedulesEntry[]
---@param comp fun(a: AllSchedulesEntry, b: AllSchedulesEntry): boolean
---@param lo_to_hi boolean?
---@return AllSchedulesEntry[]
local function sort_all_schedules(all_schedules, comp, lo_to_hi)
    local sorted_all_schedules = {}

    for _, schedule in pairs(all_schedules) do
        sorted_all_schedules[#sorted_all_schedules+1] = schedule
    end

    table.sort(sorted_all_schedules, comp)

    if not lo_to_hi then
        utils.reverse(sorted_all_schedules)
    end
    return sorted_all_schedules
end

---@param all_schedules AllSchedulesEntry[]
---@param lo_to_hi boolean?
---@return AllSchedulesEntry[]
function Exports.all_schedules_sorted_by_length(all_schedules, lo_to_hi)
    return sort_all_schedules(
        all_schedules,
        function (a, b) return #a.records < #b.records end,
        lo_to_hi
    )
end

---@param all_schedules AllSchedulesEntry[]
---@param lo_to_hi boolean?
---@return AllSchedulesEntry[]
function Exports.all_schedules_sorted_by_count_then_length(all_schedules, lo_to_hi)
    return sort_all_schedules(
        all_schedules,
        function (a, b)
            if a.count == b.count then return #a.records < #b.records end
            return a.count < b.count
        end,
        lo_to_hi
    )
end

return Exports