local utils = require("utils")

-- These are some style prototypes that the tutorial uses
-- You don't need to understand how these work to follow along
local styles = data.raw["gui-style"].default

styles["ugg_content_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on"
}

styles["ugg_controls_flow"] = {
    type = "vertical_flow_style",
    vertical_align = "center",
    horizontal_spacing = 16
}

styles["ugg_controls_textfield"] = {
    type = "textbox_style",
    width = 36
}

styles["ugg_deep_frame"] = {
    type = "frame_style",
    parent = "slot_button_deep_frame",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
    top_margin = 16,
    left_margin = 8,
    right_margin = 8,
    bottom_margin = 4
}

styles["rb_list_box_scroll_pane"] = {
  type = "scroll_pane_style",
  parent = "list_box_scroll_pane",
  graphical_set = {
    shadow = default_inner_shadow,
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 0,
    horizontally_stretchable = "on",
  },
}

styles["rb_list_box_item"] = {
  type = "button_style",
  parent = "list_box_item",
  left_padding = 4,
  right_padding = 4,
  horizontally_squashable = "on",
  horizontally_stretchable = "on",
  disabled_graphical_set = styles.list_box_item.default_graphical_set,
  disabled_font_color = styles.list_box_item.default_font_color,
}

local cursor_blueprint = utils.deep_copy(data.raw["blueprint"]["blueprint"])
cursor_blueprint.name = "tll_cursor_blueprint"
cursor_blueprint.order = "z_tll"
table.insert(cursor_blueprint.flags, "hidden")
table.insert(cursor_blueprint.flags, "only-in-cursor")

data:extend({
  {
    type="custom-input",
    name="tll_toggle_interface",
    key_sequence="CONTROL + Q",
    order = "a"
  },
  {
    type="virtual-signal",
    name="tll-select-icon",
    icon="__core__/graphics/icons/mip/select-icon-white.png",
    icon_size=40,
    order="a"
  },
  cursor_blueprint
})