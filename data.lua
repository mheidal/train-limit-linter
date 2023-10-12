local utils = require("utils")

local styles = data.raw["gui-style"].default

styles["tll_tab_content_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on"
}

styles["tll_controls_flow"] = {
    type = "vertical_flow_style",
    vertical_align = "center",
    horizontal_spacing = 16
}

styles["tll_frame_semitransparent"] = {
  type = "frame_style",
  graphical_set = {
      base = {
          type = "composition",
          filename = "__train-limit-linter__/graphics/semitransparent_pixel.png",
          corner_size = 1,
          position = {0, 0}
      }
  }
}

styles["tll_spacer"] = {
  type="empty_widget_style",
  horizontally_stretchable="on"
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