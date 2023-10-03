Exports = {}

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

---@param input string: string possibly containing rich text (format: [foo.bar]). Return with alt rich text format (format: [img=foo.bar])
---@return string
function Exports.swap_rich_text_format_to_img(input)
    local modified = input:gsub("%[(%w+)=([%w%-_]+)%]", "[img=%1.%2]")
    return modified
end

---@param input string: string possibly containing rich text (format: [foo.bar]). Return with alt rich text format (format: [img=foo.bar])
---@return string
function Exports.swap_rich_text_format_to_entity(input)
    local modified = input:gsub("%[(%w+)=([%w%-_]+)%]", "[img=entity/%2]")
    return modified
end

Exports.deep_copy = deep_copy

return Exports