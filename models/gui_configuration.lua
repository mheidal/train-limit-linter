local constants = require("constants")

local TLLModalFunctionConfiguration = require("models.modal_function_configuration")
local TLLCollapsibleFrameConfiguration = require("models.collapsible_frame_configuration")


---@class TLLGuiConfiguration
---@field last_gui_location GuiLocation?
---@field last_modal_location GuiLocation?
---@field modal_open boolean
---@field modal_function_configuration TLLModalFunctionConfiguration
---@field main_interface_selected_tab number?
---@field main_interface_open boolean
---@field collapsible_frame_configuration TLLCollapsibleFrameConfiguration

local TLLGuiConfiguration = {}
local mt = { __index = TLLGuiConfiguration }
script.register_metatable("TLLGuiConfiguration", mt)

function TLLGuiConfiguration.new()
    local self = {
        last_gui_location = nil,
        last_modal_location = nil,
        modal_open=false,
        modal_function_configuration = TLLModalFunctionConfiguration.new(),
        main_interface_open=false,
        collapsible_frame_configuration = TLLCollapsibleFrameConfiguration.new(),
    }
    setmetatable(self, mt)
    return self
end

function TLLGuiConfiguration:change_remove_train_option(new_option)
    if not constants.remove_train_option_enums[new_option] then error("No such train option") end
    self.remove_train_option = new_option
end

return TLLGuiConfiguration