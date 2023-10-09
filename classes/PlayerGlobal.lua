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
---@field hide_content_frame LuaGuiElement?
---@field display_content_frame LuaGuiElement?
---@field exclude_content_frame LuaGuiElement?
---@field settings_content_frame LuaGuiElement?
---@field hidden_keywords_frame LuaGuiElement?
---@field fuel_amount_flows table<string, LuaGuiElement> -- string is a fuel category (e.g. 'chemical')