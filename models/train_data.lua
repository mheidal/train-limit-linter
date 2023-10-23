local Exports = {}

local function build_train_data()
    local train_data = {}
    for _, surface in pairs(game.surfaces) do
        for _, train in pairs(surface.get_trains()) do
            ---@type LuaTrain
            train = train
            local rolling_stock_unit_numbers = {}
            for _, carriage in pairs(train.carriages) do
                if carriage.unit_number then
                    table.insert(rolling_stock_unit_numbers, carriage.unit_number)
                    script.register_on_entity_destroyed(carriage)
                end
            end
            train_data[train.id] = rolling_stock_unit_numbers
        end
    end
    return train_data
end

Exports.build_train_data = build_train_data

return Exports