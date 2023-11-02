local utils = require("utils")
local data_util = require("__flib__.data-util")

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

styles["tll_horizontal_controls_flow"] = {
  type = "horizontal_flow_style",
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

styles["tll_content_scroll_pane"] = {
  type="scroll_pane_style",
  vertically_stretchable="on"
}

styles["tll_spacer"] = {
  type="empty_widget_style",
  horizontally_stretchable="on"
}

styles["tll_horizontal_stretch_squash_flow"] = {
  type="horizontal_flow_style",
  horizontally_stretchable="on",
  horizontally_squashable="on",
}

styles["tll_horizontal_stretch_squash_label"] = {
  type="label_style",
  horizontally_stretchable="on",
  horizontally_squashable="on",
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
    key_sequence="CONTROL + O",
    order = "a"
  },
  {
    type="virtual-signal",
    name="tll-select-icon",
    icon="__core__/graphics/icons/mip/select-icon-white.png",
    icon_size=40,
    order="a"
  },
  {
    type="virtual-signal",
    name="tll-circuit-connection-warning-icon",
    icon="__train-limit-linter__/graphics/circuit-warning-icon.png",
    icon_size=64,
    order="a"
  },
  {
    type="virtual-signal",
    name="tll-manual-warning-icon",
    icon="__train-limit-linter__/graphics/manual-warning-icon.png",
    icon_size=64,
    order="a"
  },
  {
    type="virtual-signal",
    name="tll-not-set-warning-icon",
    icon="__train-limit-linter__/graphics/not-set-warning-icon.png",
    icon_size=64,
    order="a"
  },
  cursor_blueprint,
  {
    type="shortcut",
    name="tll_toggle_interface",
    action="lua",
    icon=data_util.build_sprite(nil, {0, 0}, "__train-limit-linter__/graphics/shortcut.png", 32, 2),
    small_icon=data_util.build_sprite(nil, {0, 32}, "__train-limit-linter__/graphics/shortcut.png", 24, 2),
    diabled_icon=data_util.build_sprite(nil, {48, 0}, "__train-limit-linter__/graphics/shortcut.png", 32, 2),
    disabled_small_icon=data_util.build_sprite(nil, {36, 32}, "__train-limit-linter__/graphics/shortcut.png", 24, 2),
    toggleable=true,
    associated_control_input="tll_toggle_interface"
  }
})