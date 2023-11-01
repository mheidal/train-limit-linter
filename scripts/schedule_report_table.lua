local constants = require("constants")
local utils = require("utils")

---@class SurfaceTrainScheduleGroups
---@field surface string
---@field train_schedule_groups LuaTrain[][]


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

---@param player LuaPlayer
---@param train_schedule_group table: array[LuaTrain]
---@param surface LuaSurface
---@param enabled_excluded_keywords table: array[toggleable_item]
---@return string|number: sum of train limits, or enums defined in constants file to indicate special values
function Exports.get_train_station_limits(player, train_schedule_group, surface, enabled_excluded_keywords)
    local sum_of_limits = 0
    local shared_schedule = train_schedule_group[1].schedule

    for _, record in pairs(shared_schedule.records) do
        local station_is_excluded = false
        for _, enabled_keyword in pairs(enabled_excluded_keywords) do
            local alt_rich_text_format_img = utils.swap_rich_text_format_to_img(enabled_keyword)
            local alt_rich_text_format_entity = utils.swap_rich_text_format_to_entity(enabled_keyword)
            if (string.find(record.station, enabled_keyword, nil, true)
                or string.find(record.station, alt_rich_text_format_img, nil, true)
                or string.find(record.station, alt_rich_text_format_entity, nil, true)
                ) then
                station_is_excluded = true
            end
        end
        if not station_is_excluded then
            for _, train_stop in pairs(surface.get_train_stops({name=record.station})) do
                -- no train limit is implemented as limit == 2 ^ 32 - 1
                if train_stop.trains_limit == (2 ^ 32) - 1 then
                    return constants.train_stop_limit_enums.not_set
                else
                    sum_of_limits = sum_of_limits + train_stop.trains_limit
                end
            end
        end
    end
    return sum_of_limits
end

-- Takes two blueprints. Both have entities 1 thru N_1 and N_2. 
-- Increments each entity's entity_number in the second blueprint by N_1.
---@param entity_list_1 BlueprintEntity[]?
---@param entity_list_2 BlueprintEntity[]?
---@return BlueprintEntity[]
local function combine_blueprint_entities(entity_list_1, entity_list_2)
    local combined = {}
    local increment = entity_list_1 and #entity_list_1 or 0
    if entity_list_1 then for i, entity in pairs(entity_list_1) do
            combined[i] = entity
    end end

    if entity_list_2 then for i, entity in pairs(entity_list_2) do
        combined[i + increment] = entity
    end end
    
    return combined
end

---@param player LuaPlayer
---@param train_length number
---@return table?
local function get_snap_to_grid(player, train_length)
    local config = global.players[player.index].model.blueprint_configuration
    if config.snap_enabled then
        if config.snap_direction == constants.snap_directions.vertical then
            return {x = train_length, y = config.snap_width}
        else
            return {x = config.snap_width, y = train_length}
        end
    else
        return nil
    end
end

--rotate x and y around the origin by the specified angle (radians)
---@param x number
---@param y number
---@param angle number
---@return table<string, number>
---     format {x: number, y: number}
local function rotate_around_origin(x, y, angle)
    local cosAngle = math.cos(angle)
    local sinAngle = math.sin(angle)

    -- Perform rotation
    local rotatedX = cosAngle * x - sinAngle * y
    local rotatedY = sinAngle * x + cosAngle * y

    return {x = rotatedX, y = rotatedY}
end

---@param entities BlueprintEntity[]
---@param x number
---@param y number
---@return BlueprintEntity[]
local function translate_blueprint_entities(entities, x, y)
    for i, entity in pairs(entities) do
        entity.position.x = entity.position.x + x
        entity.position.y = entity.position.y + y
    end
    return entities
end

---Take a train's entities. Find a locomotive. Rotate all the entities so that the locomotive should point towards the player's currently set orientation. 
---@param entities BlueprintEntity[]
---@return BlueprintEntity[]
local function orient_train_entities(entities, new_orientation)
    local main_orientation
    for _, entity in pairs(entities) do
        -- check if the entity is a locomotive
        -- type == "locomotive" is not available on BlueprintEntity, but it is visible on the LuaEntityPrototype
        local entity_proto = game.entity_prototypes[entity.name]
        if entity_proto.type == "locomotive" then
            main_orientation = entity.orientation
            break
        end
    end
    if not main_orientation then return entities end

    local goal_angle = 2 * math.pi * new_orientation
    local current_angle = main_orientation * 2 * math.pi
    local angle_to_rotate = goal_angle - current_angle

    for _, entity in pairs(entities) do
        entity.position = rotate_around_origin(entity.position.x, entity.position.y, angle_to_rotate)
        if entity.orientation == main_orientation then
            entity.orientation = new_orientation
        else
            entity.orientation = (new_orientation + 0.5) % 1
        end
    end
    
    return entities
end


-- Given a template train, creates a blueprint containing a copy of that train.
-- Can use trains at any angle.
-- First, create a main blueprint.
-- Next, for each carriage in the train, create a blueprint containing only that carriage and set that carriage's position in the blueprint to be 7 higher than the last and set its orientation to be either up or down.
-- Next, combine all those blueprints.
-- Next, add fuel to the trains and add snapping to the blueprint as configured in the model.
---@param player LuaPlayer
---@param train LuaTrain
---@param surface_name string
function Exports.create_blueprint_from_train(player, train, surface_name)

    ---@type TLLPlayerGlobal
    local player_global = global.players[player.index]

    local surface = game.get_surface(surface_name)
    if surface == nil then return end
    local script_inventory = game.create_inventory(2)
    local aggregated_blueprint_slot = script_inventory[1]
    aggregated_blueprint_slot.set_stack{name="tll_cursor_blueprint"}
    local single_carriage_slot = script_inventory[2]
    single_carriage_slot.set_stack{name="tll_cursor_blueprint"}

    local prev_vert_offset = 0
    local prev_orientation = nil
    local prev_was_counteraligned = false
    local first_vert_offset_diff = nil

    for _, carriage in pairs(train.carriages) do
        single_carriage_slot.create_blueprint{surface=surface, area=carriage.bounding_box, force=player.force, include_trains=true, include_entities=false}
        local new_blueprint_entities = single_carriage_slot.get_blueprint_entities()
        if new_blueprint_entities == nil then return end

        local carriage_prototype = game.entity_prototypes[carriage.name]
        local diff = carriage_prototype.joint_distance + carriage_prototype.connection_distance
        local vert_offset = prev_vert_offset + diff
        if not first_vert_offset_diff then first_vert_offset_diff = diff end

        new_blueprint_entities[1].position = {x=0, y= -1 * vert_offset}

        if prev_orientation == nil then
            prev_orientation = carriage.orientation
            new_blueprint_entities[1].orientation = constants.orientations.d
        else
            local orientation_diff = math.abs(prev_orientation - new_blueprint_entities[1].orientation) % 1
            orientation_diff = math.min(orientation_diff, 1 - orientation_diff)
            if orientation_diff < 0.25 then
                if prev_was_counteraligned then
                    new_blueprint_entities[1].orientation = constants.orientations.u
                else
                    new_blueprint_entities[1].orientation = constants.orientations.d
                end
            else
                if prev_was_counteraligned then
                    new_blueprint_entities[1].orientation = constants.orientations.d
                else
                    new_blueprint_entities[1].orientation = constants.orientations.u
                end
                prev_was_counteraligned = not prev_was_counteraligned
            end
        end
        prev_orientation = carriage.orientation
        prev_vert_offset = vert_offset
        local combined_blueprint_entities = combine_blueprint_entities(new_blueprint_entities, aggregated_blueprint_slot.get_blueprint_entities())
        aggregated_blueprint_slot.set_blueprint_entities(combined_blueprint_entities)
    end

    local aggregated_entities = aggregated_blueprint_slot.get_blueprint_entities()
    if not aggregated_entities then return end
    for _, entity in pairs(aggregated_entities) do
        local entity_prototype = game.entity_prototypes[entity.name]
        local items_to_add = {}
        if player_global.model.fuel_configuration.add_fuel then
            local accepted_fuel_categories = global.model.fuel_category_data.locomotives_fuel_categories[entity.name]
            if accepted_fuel_categories then
                for _, accepted_fuel_category in pairs(accepted_fuel_categories) do
                    local fuel_category_config = player_global.model.fuel_configuration.fuel_category_configurations[accepted_fuel_category]
                    if fuel_category_config.selected_fuel then
                        local number_of_fuel_slots = entity_prototype.burner_prototype.fuel_inventory_size
                        local maximum_fuel = number_of_fuel_slots * fuel_category_config:get_fuel_stack_size()
                        local fuel_amount_to_add = maximum_fuel > fuel_category_config.fuel_amount and fuel_category_config.fuel_amount or maximum_fuel
                        items_to_add[fuel_category_config.selected_fuel] = fuel_amount_to_add
                        break
                    end
                end
            end
        end
        entity.items = items_to_add
    end
    aggregated_entities = translate_blueprint_entities(aggregated_entities, 1, prev_vert_offset + math.ceil(first_vert_offset_diff / 2)) -- align with blueprint snap
    aggregated_entities = orient_train_entities(aggregated_entities, player_global.model.blueprint_configuration.new_blueprint_orientation)

    aggregated_blueprint_slot.set_blueprint_entities(aggregated_entities)
    aggregated_blueprint_slot.blueprint_snap_to_grid = get_snap_to_grid(player, prev_vert_offset)
    player.add_to_clipboard(aggregated_blueprint_slot)
    player.activate_paste()
    script_inventory.destroy()
end

return Exports