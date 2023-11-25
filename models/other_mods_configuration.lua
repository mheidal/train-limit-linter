local constants = require("constants")

---@class TLLOtherModsConfiguration
---@field TrainGroups_configuration TLLTrainGroupsConfiguration

---@class TLLTrainGroupsConfiguration
---@field copy_train_group boolean
---@field toggle_copy_train_group fun(self: TLLTrainGroupsConfiguration)

-- TrainGroups https://mods.factorio.com/mod/TrainGroups

local TLLTrainGroupsConfiguration = {}
local TrainGroups_mt = { __index = TLLTrainGroupsConfiguration }
script.register_metatable("TLLTrainGroupsConfiguration", TrainGroups_mt)

function TLLTrainGroupsConfiguration.new()
    local self = {
        copy_train_group = true,
    }
    setmetatable(self, TrainGroups_mt)
    return self
end

function TLLTrainGroupsConfiguration:toggle_copy_train_group()
    self.copy_train_group = not self.copy_train_group
end

-- parent class containing other mod configurations

local TLLOtherModsConfiguration = {}
local other_mods_mt = { __index = TLLOtherModsConfiguration }
script.register_metatable("TLLOtherModsConfiguration", other_mods_mt)

function TLLOtherModsConfiguration.new()
    local self = {
        TrainGroups_configuration = TLLTrainGroupsConfiguration.new(),
    }
    setmetatable(self, other_mods_mt)
    return self
end

return TLLOtherModsConfiguration