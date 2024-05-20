local constants = {}

constants.actions = {
    main_interface_switch_tab="main_interface_switch_tab",
    close_window="close_window",

    toggle_keyword="toggle_keyword",
    delete_keyword="delete_keyword",
    keyword_textfield_enter_text="keyword_textfield_enter_text",
    keyword_textfield_apply="keyword_textfield_apply",
    delete_all_keywords="delete_all_keywords",
    set_keyword_match_type="set_keyword_match_type",

    train_schedule_create_blueprint="train_schedule_create_blueprint",
    train_schedule_create_blueprint_and_ping_trains="train_schedule_create_blueprint_and_ping_trains",
    train_schedule_remove_trains="train_schedule_remove_trains",
    toggle_show_all_surfaces="toggle_show_all_surfaces",
    toggle_show_satisfied="toggle_show_satisfied",
    toggle_show_not_set="toggle_show_not_set",
    toggle_show_dynamic="toggle_show_dynamic",
    toggle_show_single_station_schedules="toggle_show_single_station_schedules",
    toggle_show_train_limits_separately="toggle_show_train_limits_separately",

    icon_selector_textfield_apply="icon_selector_textfield_apply",
    icon_selector_icon_selected="icon_selector_icon_selected",

    set_blueprint_orientation="set_blueprint_orientation",
    toggle_blueprint_snap="toggle_blueprint_snap",
    set_blueprint_snap_width="set_blueprint_snap_width",
    toggle_blueprint_snap_direction="toggle_blueprint_snap_direction",
    toggle_include_train_stops="toggle_include_train_stops",
    toggle_limit_train_stops="toggle_limit_train_stops",
    set_default_train_limit="set_default_train_limit",

    toggle_place_trains_with_fuel="toggle_place_trains_with_fuel",
    update_fuel_amount="update_fuel_amount",
    select_fuel="select_fuel",

    open_modal="open_modal",
    close_modal="close_modal",
    focus_modal="focus_modal",
    import_keywords_button="import_keywords_button",
    import_keywords_textfield="import_keywords_textfield",

    train_stop_name_selector_search="train_stop_name_selector_search",
    train_stop_name_selector_select_name="train_stop_name_selector_select_name",

    toggle_display_settings_visible="toggle_display_settings_visible",
    toggle_blueprint_settings_visible="toggle_blueprint_settings_visible",
    toggle_fuel_settings_visible="toggle_fuel_settings_visible",
    toggle_general_settings_visible="toggle_general_settings_visible",
    toggle_other_mods_settings_visible="toggle_other_mods_settings_visible",

    toggle_opinionation="toggle_opinionation",
    change_remove_train_option="change_remove_train_option",
    toggle_train_to_remove_checkbox="toggle_train_to_remove_checkbox",
    toggle_train_to_remove_button="toggle_train_to_remove_button",
    remove_trains="remove_trains",
    open_train="open_train",

    toggle_TrainGroups_copy_train_group="toggle_TrainGroups_copy_train_group",
}

constants.orientations = {
    u=0,
    ur=0.125,
    r=0.25,
    dr=0.375,
    d=0.5,
    dl=0.625,
    l=0.75,
    ul=0.875
}

constants.snap_directions = {
    vertical="vertical",
    horizontal="horizontal"
}

constants.modal_functions = {
    export_keyword_list="export_keyword_list",
    import_keyword_list="import_keyword_list",
    train_stop_name_selector="train_stop_name_selector",
    remove_trains="remove_trains",
}

constants.keyword_lists = {
    exclude="exclude",
    hide="hide",
}

constants.style_data = {
    main_frame_size={600, 800}
}

constants.default_surface_name = "nauvis"

constants.magic_numbers = {
    -- no train limit is implemented as limit == 2 ^ 32 - 1
    train_limit_not_set=(2 ^ 32) - 1,
}

constants.remove_train_option_enums = {
    mark="mark",
    delete="delete",
}

constants.gui_element_names = {
    train_removal_modal = {
        checkbox="train_removal_modal_checkbox"
    }
}

constants.keyword_match_types = {
    exact="exact",
    substring="substring",
}

constants.supported_interfaces = {
    logistic_train_network="logistic-train-network",
    cybersyn="cybersyn",
    train_groups="TrainGroups",
    space_exploration="space-exploration",
}

return constants