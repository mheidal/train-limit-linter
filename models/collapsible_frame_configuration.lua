---@class TLLCollapsibleFrameConfiguration
---@field display_settings_visible boolean
---@field blueprint_settings_visible boolean
---@field new fun(): TLLCollapsibleFrameConfiguration
---@field toggle_display_settings_visible fun(TLLCollapsibleFrameConfiguration)
---@field toggle_blueprint_settings_visible fun(TLLCollapsibleFrameConfiguration)

local TLLCollapsibleFrameConfiguration = {}
local mt = { __index = TLLCollapsibleFrameConfiguration }
script.register_metatable("TLLCollapsibleFrameConfiguration", mt)

function TLLCollapsibleFrameConfiguration.new()
    local self = {
        display_settings_visible=true,
        blueprint_settings_visible=true,
    }
    setmetatable(self, mt)
    return self
end

function TLLCollapsibleFrameConfiguration:toggle_display_settings_visible()
    self.display_settings_visible = not self.display_settings_visible
end

function TLLCollapsibleFrameConfiguration:toggle_blueprint_settings_visible()
    self.blueprint_settings_visible = not self.blueprint_settings_visible
end

return TLLCollapsibleFrameConfiguration