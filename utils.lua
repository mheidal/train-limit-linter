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

function get_table_size(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

Exports.deep_copy = deep_copy
Exports.get_table_size = get_table_size


return Exports