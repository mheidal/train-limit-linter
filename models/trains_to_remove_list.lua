---@class TLLTrainsToRemoveList
---@field trains_to_remove table
---@field add fun(self: TLLTrainsToRemoveList, train_id: number)
---@field remove fun(self: TLLTrainsToRemoveList, train_id: number)
---@field remove_all fun(self: TLLTrainsToRemoveList)

local TLLTrainsToRemoveList = {}
local mt = { __index = TLLTrainsToRemoveList }
script.register_metatable("TLLTrainsToRemoveList", mt)

function TLLTrainsToRemoveList.new()
    local self = {
        trains_to_remove = {}
    }
    setmetatable(self, mt)
    return self
end

function TLLTrainsToRemoveList:add(train_id)
    self.trains_to_remove[train_id] = true
end

function TLLTrainsToRemoveList:remove(train_id)
    self.trains_to_remove[train_id] = nil
end

function TLLTrainsToRemoveList:remove_all()
    self.trains_to_remove = {}
end


return TLLTrainsToRemoveList