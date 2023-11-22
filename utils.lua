local Exports = {}

-- this stuff is all copied from Factory Planner
function deep_copy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for origKey, origValue in next, orig, nil do
            copy[deep_copy(origKey)] = deep_copy(origValue)
        end
        setmetatable(copy, deep_copy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function Exports.get_table_size(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

function Exports.contains(t, v)
    for _, val in pairs(t) do
        if val == v then return true end
    end
    return false
end

---@param input string: string possibly containing rich text (format: [foo.bar]). Return with alt rich text format (format: [img=foo.bar])
---@return string
function Exports.swap_rich_text_format_to_img(input)
    local modified = input:gsub("%[(%w+)=([%w%-_]+)%]", "[img=%1.%2]")
    return modified
end

---@param input string: string possibly containing rich text (format: [foo.bar]). Return with alt rich text format (format: [img=entity/bar])
---@return string
function Exports.swap_rich_text_format_to_entity(input)
    local modified = input:gsub("%[(%w+)=([%w%-_]+)%]", "[img=entity/%2]")
    return modified
end


---@param value number
---@param unit string
---@param round number
---@return string
function Exports.localize_to_metric(value, unit, round)
    local prefixes = {"Y", "Z", "E", "P", "T", "G", "M", "k", "", "m", "µ", "n", "p", "f", "a", "z", "y"}
    local index = 9

    if not round then round = 2 end

    -- Handle negative values
    local sign = ""
    if value < 0 then
        sign = "-"
        value = -value
    end

    -- Determine the appropriate prefix based on the magnitude of the value
    while value >= 1000 and index > 1 do
        value = value / 1000
        index = index - 1
    end

    local formatted_value
    if index <= 8 then
        formatted_value = string.format("%." .. tostring(round) .. "f", value)
    else
        formatted_value = string.format("%.0f", value)
    end

    formatted_value = string.match(formatted_value, "^(.-)%.0*$") or formatted_value

    return sign .. formatted_value .. " " .. prefixes[index] .. unit
end

function Exports.localize_to_percentage(value, round)
    if not round then round = 2 end
    local format_string = "%." .. tostring(round) .. "f"
    local formatted_string = string.format(format_string, value * 100)
    formatted_string = string.match(formatted_string, "^(.-)%.0*$") or formatted_string
    return formatted_string .. "%"
end

---@param records TrainScheduleRecord[]
---@return string
function Exports.train_records_to_key(records)
    local key
    for _, record in pairs(records) do
        local record_string = record.station or record.rail and "[" .. record.rail.position.x .. ", " .. record.rail.position.y .. "]" or ""
        if not key then
            key = record_string
        else
            key = key .. " → " .. record_string
        end
    end
    if not key then return "" end
    return key
end

function Exports.find_in_rich_text(superstring, substring)
    local alt_rich_text_format_img = Exports.swap_rich_text_format_to_img(substring)
    local alt_rich_text_format_entity = Exports.swap_rich_text_format_to_entity(substring)
    return (string.find(superstring, substring, nil, true)
    or string.find(superstring, alt_rich_text_format_img, nil, true)
    or string.find(superstring, alt_rich_text_format_entity, nil, true)
    )
end

---@generic V
---@param t table
---@param k any
---@param v V
---@return V
function Exports.get_or_insert(t, k, v)
    if not t[k] then
        t[k] = v
    end
    return t[k]
end

Exports.deep_copy = deep_copy

return Exports