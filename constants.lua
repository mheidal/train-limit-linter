local constants = {}

constants.actions = {
    main_interface_switch_tab="main_interface_switch_tab",
    close_window="close_window",

    toggle_excluded_keyword="toggle_excluded_keyword",
    delete_excluded_keyword="delete_excluded_keyword",
    exclude_textfield_enter_text="exclude_textfield_enter_text",
    exclude_textfield_apply="exclude_textfield_apply",
    delete_all_excluded_keywords="delete_all_excluded_keywords",

    hide_textfield_enter_text="hide_textfield_enter_text",
    hide_textfield_apply="hide_textfield_apply",
    toggle_hidden_keyword="toggle_hidden_keyword",
    delete_hidden_keyword="delete_hidden_keyword",
    delete_all_hidden_keywords="delete_all_hidden_keywords",

    train_schedule_create_blueprint="train_schedule_create_blueprint",
    train_schedule_create_blueprint_and_ping_trains="train_schedule_create_blueprint_and_ping_trains",
    train_schedule_ping_manual_trains="train_schedule_ping_manual_trains",
    toggle_show_all_surfaces="toggle_show_all_surfaces",
    toggle_show_satisfied="toggle_show_satisfied",
    toggle_show_not_set="toggle_show_not_set",
    toggle_show_manual="toggle_show_manual",
    toggle_show_dynamic="toggle_show_dynamic",
    toggle_show_settings="toggle_show_settings",
    toggle_show_single_station_schedules="toggle_show_single_station_schedules",

    icon_selector_textfield_apply="icon_selector_textfield_apply",
    icon_selector_icon_selected="icon_selector_icon_selected",

    set_blueprint_orientation="set_blueprint_orientation",
    toggle_blueprint_snap="toggle_blueprint_snap",
    set_blueprint_snap_width="set_blueprint_snap_width",
    toggle_blueprint_snap_direction="toggle_blueprint_snap_direction",

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
    train_stop_name_selector="train_stop_name_selector"
}

constants.keyword_lists = {
    exclude="exclude",
    hide="hide",
}

constants.style_data = {
    main_frame_size={600, 800}
}

constants.default_surface_name = "nauvis"

return constants