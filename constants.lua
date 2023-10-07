local constants = {}

constants.actions = {
    train_schedule_create_blueprint="train_schedule_create_blueprint",
    toggle_excluded_keyword="toggle_excluded_keyword",
    delete_excluded_keyword="delete_excluded_keyword",
    train_report_update="train_report_update",
    select_fuel="select_fuel",
    close_window="close_window",
    exclude_textfield_apply="exclude_textfield_apply",
    delete_all_excluded_keywords="delete_all_excluded_keywords",
    hide_textfield_apply="hide_textfield_apply",
    toggle_hidden_keyword="toggle_hidden_keyword",
    delete_hidden_keyword="delete_hidden_keyword",
    delete_all_hidden_keywords="delete_all_hidden_keywords",
    toggle_current_surface="toggle_current_surface",
    toggle_show_satisfied="toggle_show_satisfied",
    toggle_show_invalid="toggle_show_invalid",
    update_fuel_amount="update_fuel_amount_textfield",
    icon_selector_textfield_apply="icon_selector_textfield_apply",
    icon_selector_icon_selected="icon_selector_icon_selected",

    set_blueprint_orientation="set_blueprint_orientation",
    toggle_blueprint_snap="toggle_blueprint_snap",
    set_blueprint_snap_width="set_blueprint_snap_width",
    toggle_blueprint_snap_direction="toggle_blueprint_snap_direction",
}

constants.train_stop_limit_enums = {
    not_set = "not_set",
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

return constants