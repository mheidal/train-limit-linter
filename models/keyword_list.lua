local constants = require("constants")
local utils = require("utils")

---@class TLLKeywordList
---@field toggleable_items table<string, TLLToggleableItem>
---@field new fun(): TLLKeywordList
---@field get_enabled_keywords fun(self: TLLKeywordList): table<string, TLLToggleableItem>
---@field set_enabled fun(self: TLLKeywordList, keyword: string, enabled: boolean)
---@field toggle_enabled fun(self: TLLKeywordList, keyword: string)
---@field remove_item fun(self: TLLKeywordList, keyword: string)
---@field remove_all fun(self: TLLKeywordList)
---@field get_number_of_keywords fun(self: TLLKeywordList): number
---@field get_keywords fun(self: TLLKeywordList): table<string, TLLToggleableItem>
---@field serialize fun(self: TLLKeywordList): string
---@field add_from_serialized fun(self: TLLKeywordList, serialized: string)
---@field matches_any fun(self: TLLKeywordList, test_string: string): boolean
---@field set_match_type fun(self: TLLKeywordList, keyword: string, new_match_type: string)

---@class TLLToggleableItem
---@field enabled boolean
---@field match_type string
---@field new fun(): TLLToggleableItem
---@field toggle_enabled fun(self: TLLToggleableItem)
---@field set_enabled fun(self: TLLToggleableItem, enabled: boolean)
---@field set_match_type fun(self: TLLToggleableItem, new_match_type: string)

-- toggleable item

---@class TLLToggleableItem
local TLLToggleableItem = {}
local ti_mt = { __index = TLLToggleableItem }
script.register_metatable("TLLToggleableItem", ti_mt)

---@return TLLToggleableItem
function TLLToggleableItem.new()
    local self = {
        enabled = true,
        match_type=constants.keyword_match_types.substring,
    }
    setmetatable(self, ti_mt)
    return self
end

function TLLToggleableItem:toggle_enabled()
    self.enabled = not self.enabled
end

function TLLToggleableItem:set_enabled(enabled)
    self.enabled = enabled
end

function TLLToggleableItem:set_match_type(new_match_type)
    if not constants.keyword_match_types[new_match_type] then return end
    self.match_type = new_match_type
end

-- keyword list

---@class TLLKeywordList
local TLLKeywordList = {}
local kwl_mt = { __index = TLLKeywordList }
script.register_metatable("TLLKeywordList", kwl_mt)

---@return TLLKeywordList
function TLLKeywordList.new()
    local self = { toggleable_items = {} }
    setmetatable(self, kwl_mt)
    return self
end

---@return table<string, TLLToggleableItem>
function TLLKeywordList:get_enabled_keywords()
    local enabled_keywords = {}
    for value, toggleable_item in pairs(self.toggleable_items) do
        if toggleable_item.enabled then
            enabled_keywords[value] = toggleable_item
        end
    end
    return enabled_keywords
end

---@param keyword string
---@param enabled boolean
function TLLKeywordList:set_enabled(keyword, enabled)
    if self.toggleable_items[keyword] == nil then
        self.toggleable_items[keyword] = TLLToggleableItem.new()
    end
    self.toggleable_items[keyword]:set_enabled(enabled)
end

---@param keyword string
function TLLKeywordList:toggle_enabled(keyword)
    if not self.toggleable_items[keyword] then return end
    self.toggleable_items[keyword]:toggle_enabled()
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

function TLLKeywordList:matches_any(test_string)
    for keyword, toggleable_item in pairs(self:get_enabled_keywords()) do
        if toggleable_item.match_type == constants.keyword_match_types.substring then
            if utils.find_in_rich_text(test_string, keyword) then
                return true
            end
        elseif toggleable_item.match_type == constants.keyword_match_types.exact then
            if test_string == keyword then
                return true
            end
        end
    end
    return false
end

function TLLKeywordList:set_match_type(keyword, new_match_type)
    if not self.toggleable_items[keyword] then return end
    self.toggleable_items[keyword]:set_match_type(new_match_type)
end

return TLLKeywordList