local constants = require("constants")

---@class TLLModalFunctionConfiguration
---@field func string?
---@field args table?
---@field new fun(): TLLModalFunctionConfiguration
---@field set_modal_content_function fun(self: TLLModalFunctionConfiguration, func: string)
---@field get_modal_content_function fun(self: TLLModalFunctionConfiguration): string?
---@field clear_modal_content_function fun(self: TLLModalFunctionConfiguration)
---@field set_modal_content_args fun(self: TLLModalFunctionConfiguration, args: table?)
---@field get_modal_content_args fun(self: TLLModalFunctionConfiguration): table?
---@field clear_modal_content_args fun(self: TLLModalFunctionConfiguration)

---@class TLLModalFunctionConfiguration
local TLLModalFunctionConfiguration = {}
local mt = { __index = TLLModalFunctionConfiguration }
script.register_metatable("TLLModalFunctionConfiguration", mt)

function TLLModalFunctionConfiguration.new()
    local self = {
        modal_content_function = nil
    }
    setmetatable(self, mt)
    return self
end


function TLLModalFunctionConfiguration:set_modal_content_function(func)
    if not constants.modal_functions[func] then return end
    self.func = func
end

function TLLModalFunctionConfiguration:get_modal_content_function()
    return self.func
end

function TLLModalFunctionConfiguration:clear_modal_content_function()
    self.func = nil
end

function TLLModalFunctionConfiguration:set_modal_content_args(args)
    self.args = args
end

function TLLModalFunctionConfiguration:get_modal_content_args()
    return self.args
end

function TLLModalFunctionConfiguration:clear_modal_content_args()
    self.args = nil
end

return TLLModalFunctionConfiguration