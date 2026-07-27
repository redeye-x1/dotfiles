local colors = require("colors")

-- Height 39 and the horizontal padding of 10 come from the simple-bar
-- customStyles block, so the bar occupies exactly the same strip as before.
sbar.bar({
  height = 39,
  color = colors.background,
  padding_left = 10,
  padding_right = 10,
  blur_radius = 0,
  position = "top",
  sticky = true,
  topmost = false,
  y_offset = 0,
  margin = 0,
})
