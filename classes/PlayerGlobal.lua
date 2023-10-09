---@class TLLPlayerGlobal
---@field model TLLPlayerModel
---@field view TLLPlayerView


---@class TLLPlayerModel
---@field blueprint_configuration TLLBlueprintConfiguration
---@field schedule_table_configuration TLLScheduleTableConfiguration
---@field fuel_configuration TLLFuelConfiguration
---@field excluded_keywords TLLKeywordList
---@field hidden_keywords TLLKeywordList
---@field last_gui_location GuiLocation?

---@class TLLPlayerView
---@field main_frame LuaGuiElement?
---@field report_frame LuaGuiElement?

---@class TLLKeywordList
---@field toggleable_items table<string, TLLToggleableItemData>

---@class TLLToggleableItemData
---@field enabled boolean