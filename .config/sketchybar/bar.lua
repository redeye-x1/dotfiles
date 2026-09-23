local colors = require("colors")
local settings = require("settings")

-- Padding stays 0: items/click_shield.lua supplies it with edge items, since
-- its bracket cannot reach into bar padding.
sbar.bar({
  height = settings.bar_height,
  color = colors.background,
  padding_left = 0,
  padding_right = 0,
  blur_radius = 0,
  position = "top",
  sticky = true,
  topmost = false,
  y_offset = 0,
  margin = 0,
})
