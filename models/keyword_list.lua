utils = require("utils")

exports = {}

---@class ToggleableItem
toggleable_item = {
    enabled=true
}

---@class UniqueToggleableList
-- Array of toggleable_item, where key is the name and value has an enabled flag
keyword_list = {
    toggleable_items={}
}

keyword_list.get_enabled_strings = function(items)
    local enabled_keywords = {}

    for value, toggleable_item in pairs(items) do
        if toggleable_item.enabled then table.insert(enabled_keywords, value) end
    end
    return enabled_keywords
end

keyword_list.set_enabled = function(list, keyword, enabled)
    if list.toggleable_items[keyword] == nil then
        list.toggleable_items[keyword] = utils.deepCopy(toggleable_item)
    end
    list.toggleable_items[keyword] = {enabled=enabled}
end

exports.toggleable_item = toggleable_item
exports.keyword_list = keyword_list

exports.get_enabled_strings = keyword_list.get_enabled_strings
exports.set_enabled = keyword_list.set_enabled

return exports