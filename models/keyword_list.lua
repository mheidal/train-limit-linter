---@class TLLKeywordList
---@field toggleable_items table<string, TLLToggleableItem>
---@field new fun(self: TLLKeywordList): TLLKeywordList
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

-- toggleable item

TLLToggleableItem = {}

function TLLToggleableItem:new()
    local new_object = {
        enabled=true
    }
    setmetatable(new_object, self)
    self.__index = self
    return new_object
end

-- keyword list

TLLKeywordList = {}

function TLLKeywordList:new()
    local new_object = {
        toggleable_items={}
    }
    setmetatable(new_object, self)
    self.__index = self
    return new_object
end

---@return string[]
function TLLKeywordList:get_enabled_keywords()
    local enabled_keywords = {}

    for value, toggleable_item in pairs(self.toggleable_items) do
        if toggleable_item.enabled then table.insert(enabled_keywords, value) end
    end
    return enabled_keywords
end

---@param keyword string
---@param enabled boolean
function TLLKeywordList:set_enabled(keyword, enabled)
    if self.toggleable_items[keyword] == nil then
        self.toggleable_items[keyword] = TLLToggleableItem:new()
    end
    self.toggleable_items[keyword].enabled = enabled
end

---@param keyword string
function TLLKeywordList:toggle_enabled(keyword)
    if self.toggleable_items[keyword] == nil then
        return
    end
    self.toggleable_items[keyword].enabled = not self.toggleable_items[keyword].enabled
end

---@param keyword string
function TLLKeywordList:remove_item(keyword)
    self.toggleable_items[keyword] = nil
end

function TLLKeywordList:remove_all()
    self.toggleable_items = {}
end

Exports.TLLKeywordList = TLLKeywordList

return Exports