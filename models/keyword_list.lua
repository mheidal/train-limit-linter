local utils = require("utils")

---@class TLLKeywordList
---@field toggleable_items table<string, TLLToggleableItem>
---@field new fun(self: TLLKeywordList): TLLKeywordList
---@field get_enabled_keywords fun(self: TLLKeywordList): string[]
---@field set_enabled fun(self: TLLKeywordList, keyword: string, enabled: boolean)
---@field toggle_enabled fun(self: TLLKeywordList, keyword: string)
---@field remove_item fun(self: TLLKeywordList, keyword: string)
---@field remove_all fun(self: TLLKeywordList)
---@field get_number_of_keywords fun(self: TLLKeywordList): number
---@field get_keywords fun(self: TLLKeywordList): table<string, TLLToggleableItem>
---@field serialize fun(self: TLLKeywordList): string
---@field add_from_serialized fun(self: TLLKeywordList, serialized: string)

---@class TLLToggleableItem
---@field enabled boolean
---@field new fun(): TLLToggleableItem

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

---@return TLLKeywordList
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

---@return number
function TLLKeywordList:get_number_of_keywords()
    return utils.get_table_size(self.toggleable_items)
end

---@return table<string, TLLToggleableItem>
function TLLKeywordList:get_keywords()
    return self.toggleable_items
end

---@return string
function TLLKeywordList:serialize()
    local keywords = {}
    for keyword, _ in pairs(self.toggleable_items) do
        table.insert(keywords, keyword)
    end
    local dump = serpent.dump(keywords)
    local encoded = game.encode_string(dump)
    if not encoded then return "" end
    return encoded
end

---@param serialized string
function TLLKeywordList:add_from_serialized(serialized)
    local decoded = game.decode_string(serialized)
    if not decoded then return end
    local successful, keywords = serpent.load(decoded)
    if not successful then return end
    for _, keyword in pairs(keywords) do
        self:set_enabled(keyword, true)
    end
end

Exports.TLLKeywordList = TLLKeywordList

return Exports