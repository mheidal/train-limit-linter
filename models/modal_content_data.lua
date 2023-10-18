
---@class TLLModalContentData
---@field close_button_visible boolean
---@field titlebar_visible boolean
---@field titlebar_caption LocalisedString
---@field new fun(): TLLModalContentData
---@field set_close_button_visible fun(self: TLLModalContentData, value: boolean)
---@field set_titlebar_visible fun(self: TLLModalContentData, value: boolean)
---@field set_titlebar_caption fun(self: TLLModalContentData, caption: LocalisedString)

---@class TLLModalContentData
local TLLModalContentData = {}
local mt = { __index = TLLModalContentData }
script.register_metatable("TLLModalContentData", mt)

function TLLModalContentData.new()
    local self = {
        close_button_visible = false,
        titlebar_visible=true,
        titlebar_caption="",
    }
    setmetatable(self, mt)
    return self
end

function TLLModalContentData:set_close_button_visible(value)
    self.close_button_visible = value
end

function TLLModalContentData:set_titlebar_visible(value)
    self.titlebar_visible = value
end

function TLLModalContentData:set_titlebar_caption(caption)
    self.titlebar_caption = caption
end

return TLLModalContentData