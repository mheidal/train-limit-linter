---@class TLLCollapsibleFrameConfiguration
---@field display_settings_visible boolean
---@field blueprint_settings_visible boolean
---@field fuel_settings_visible boolean
---@field general_settings_visible boolean
---@field new fun(): TLLCollapsibleFrameConfiguration
---@field toggle_display_settings_visible fun(TLLCollapsibleFrameConfiguration)
---@field toggle_blueprint_settings_visible fun(TLLCollapsibleFrameConfiguration)
---@field toggle_fuel_settings_visible fun(TLLCollapsibleFrameConfiguration)
---@field toggle_general_settings_visible fun(TLLCollapsibleFrameConfiguration)

local TLLCollapsibleFrameConfiguration = {}
local mt = { __index = TLLCollapsibleFrameConfiguration }
script.register_metatable("TLLCollapsibleFrameConfiguration", mt)

function TLLCollapsibleFrameConfiguration.new()
    local self = {
        display_settings_visible=true,
        blueprint_settings_visible=true,
        fuel_settings_visible=true,
        general_settings_visible=true,
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

function TLLCollapsibleFrameConfiguration:toggle_fuel_settings_visible()
    self.fuel_settings_visible = not self.fuel_settings_visible
end

function TLLCollapsibleFrameConfiguration:toggle_general_settings_visible()
    self.general_settings_visible = not self.general_settings_visible
end

return TLLCollapsibleFrameConfiguration