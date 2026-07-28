local colors = require("colors")
local settings = require("settings")

-- Shared defaults for every item. Individual widgets override background.color
-- only, because simple-bar gives each widget its own colour rather than one
-- uniform pill.
sbar.default({
  updates = "when_shown",
  scroll_texts = true,

  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = settings.icon_size,
    },
    color = colors.white,
    padding_left = settings.item_padding,
    padding_right = 5,
  },

  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = settings.font_size,
    },
    -- simple-bar's noColorInData forces every data label to --white while the
    -- widget background stays coloured, so the label colour is fixed here.
    color = colors.white,
    padding_left = 0,
    padding_right = settings.item_padding,
  },

  background = {
    height = settings.item_height,
    corner_radius = settings.item_radius,
    color = colors.minor,
    border_width = 0,
  },

  padding_left = settings.paddings,
  padding_right = settings.paddings,
})
