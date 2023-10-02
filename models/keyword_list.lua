utils = require("utils")

Exports = {}

---@class ToggleableItem
toggleable_item = {
    enabled=true
}

---@class UniqueToggleableList
-- Array of toggleable_item, where key is the name and value has an enabled flag
keyword_list = {
    toggleable_items={}
}

keyword_list.get_enabled_strings = function(list)
    local enabled_keywords = {}

    for value, toggleable_item in pairs(list.toggleable_items) do
        if toggleable_item.enabled then table.insert(enabled_keywords, value) end
    end
    return enabled_keywords
end

keyword_list.set_enabled = function(list, keyword, enabled)
    if list.toggleable_items[keyword] == nil then
        list.toggleable_items[keyword] = utils.deep_copy(toggleable_item)
    end
    list.toggleable_items[keyword].enabled = enabled
end

keyword_list.toggle_enabled = function(list, keyword)
    if list.toggleable_items[keyword] == nil then
        return
    end
    list.toggleable_items[keyword].enabled = not list.toggleable_items[keyword].enabled
end

keyword_list.remove_item = function(list, keyword)
    list.toggleable_items[keyword] = nil
end

Exports.toggleable_item = toggleable_item
Exports.keyword_list = keyword_list

Exports.get_enabled_strings = keyword_list.get_enabled_strings
Exports.set_enabled = keyword_list.set_enabled
Exports.toggle_enabled = keyword_list.toggle_enabled
Exports.remove_item = keyword_list.remove_item

return Exports