---@class TLLKeywordList
---@field toggleable_items table<string, TLLToggleableItem>
---@field get_enabled_keywords fun(self: TLLKeywordList): string[]
---@field set_enabled fun(self: TLLKeywordList, keyword: string, enabled: boolean)
---@field toggle_enabled fun(self: TLLKeywordList, keyword: string)
---@field remove_item fun(self: TLLKeywordList, keyword: string)
---@field remove_all fun(self: TLLKeywordList)
---@field get_new_keyword_list fun(): TLLKeywordList

---@class TLLToggleableItem
---@field enabled boolean
---@field get_new_toggleable_item fun(): TLLToggleableItem

Exports = {}

toggleable_item = {}

function toggleable_item.get_new_toggleable_item()
    return deep_copy({
        enabled=true
    })
end

-- Table of toggleable_item, where key is the name and value has an enabled flag
keyword_list = {
    toggleable_items={}
}

---@return string[]
function keyword_list:get_enabled_keywords()
    local enabled_keywords = {}

    for value, toggleable_item in pairs(self.toggleable_items) do
        if toggleable_item.enabled then table.insert(enabled_keywords, value) end
    end
    return enabled_keywords
end

---@param keyword string
---@param enabled boolean
function keyword_list:set_enabled(keyword, enabled)
    if self.toggleable_items[keyword] == nil then
        self.toggleable_items[keyword] = deep_copy(toggleable_item)
    end
    self.toggleable_items[keyword].enabled = enabled
end

---@param keyword string
function keyword_list:toggle_enabled(keyword)
    if self.toggleable_items[keyword] == nil then
        return
    end
    self.toggleable_items[keyword].enabled = not self.toggleable_items[keyword].enabled
end

---@param keyword string
function keyword_list:remove_item(keyword)
    self.toggleable_items[keyword] = nil
end

function keyword_list:remove_all()
    self.toggleable_items = {}
end

---@return TLLKeywordList
function get_new_keyword_list()
    return deep_copy(keyword_list)
end

Exports.get_new_keyword_list = get_new_keyword_list

return Exports