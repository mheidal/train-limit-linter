exports = {}

---@class ToggleableItem
toggleable_item = {
    enabled=true
}

---@class UniqueToggleableList
-- Array of toggleable_item, where key is the name and value has an enabled flag
unique_toggleable_list = {
    toggleable_items={}
}

unique_toggleable_list.get_enabled_strings = function(items)
    local enabled_keywords = {}

    for value, toggleable_item in pairs(items) do
        if toggleable_item.enabled then table.insert(enabled_keywords, value) end
    end
    return enabled_keywords
end

exports.toggleable_item = toggleable_item
exports.unique_toggleable_list = unique_toggleable_list

return exports