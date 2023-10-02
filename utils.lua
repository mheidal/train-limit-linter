exports = {}

-- this stuff is all copied from Factory Planner
function deepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for origKey, origValue in next, orig, nil do
            copy[deepCopy(origKey)] = deepCopy(origValue)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
exports.deepCopy = deepCopy


return exports