local constants = require("constants")

local Exports = {}

---@param parent LuaGuiElement
---@param general_config TLLGeneralConfiguration
function Exports.add_train_removal_radio_buttons(parent, general_config)

    parent.add{type="label", caption=""}

    parent.add{
        type="radiobutton",
        caption={"tll.mark_for_deconstruction"},
        tags={
            action=constants.actions.change_remove_train_option,
            new_option=constants.remove_train_option_enums.mark
        },
        state=general_config.remove_train_option == constants.remove_train_option_enums.mark,
    }

    parent.add{
        type="radiobutton",
        caption={"tll.delete_trains"},
        tags={
            action=constants.actions.change_remove_train_option,
            new_option=constants.remove_train_option_enums.delete
        },
        state=general_config.remove_train_option == constants.remove_train_option_enums.delete,
    }
end

return Exports