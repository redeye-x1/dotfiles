local colors = require("colors")
local settings = require("settings")
local hover = require("helpers.hover")

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
    -- A ring is kept ready on every item, invisible until the pointer arrives.
    -- See helpers/hover.lua; giving it a width up front means the hover only
    -- has to change a colour and cannot shift the layout.
    border_width = 1,
    border_color = hover.ring,
  },

  padding_left = settings.paddings,
  padding_right = settings.paddings,
})
