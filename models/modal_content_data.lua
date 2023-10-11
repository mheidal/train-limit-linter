
---@class TLLModalContentData
---@field close_button_visible boolean

local Exports = {}

TLLModalContentData = {}

---@param o table?
function TLLModalContentData:new(o)
    local new_object = o or {
        close_button_visible = false
    }
    setmetatable(new_object, self)
    self.__index = self
    return new_object
end

Exports.TLLModalContentData = TLLModalContentData

return Exports