return {
  paddings = 3,

  -- Derived from .simplebarrc: "font": "SF Pro", "fontSize": "11px".
  font = require("helpers.default_font"),
  font_size = 11.0,
  icon_size = 13.0,

  -- Widget geometry, derived from the simple-bar customStyles block:
  --   .data-widget { padding: 3px 9px; max-height: 30px }
  --   .spaces      { height: 25px }
  item_height = 24,
  item_radius = 5,
  item_padding = 9,
  workspace_height = 25,

  -- The digit's field inside a workspace pill. Deliberately lower than the pill
  -- so it reads as an inset chip: sketchybar has no per-corner radius, so a
  -- full-height field would round its inner edge too and cut a notch into the
  -- pill where it meets the app icons.
  digit_chip_height = 18,
  digit_chip_radius = 4,

  -- The app icon font shipped by the font-sketchybar-app-font cask. Labels use
  -- the :slug: form from helpers/app_icons.lua, which the font turns into a
  -- glyph via ligatures.
  app_icon_font = "sketchybar-app-font",
  app_icon_size = 12.0,
  -- Nudges the app icons against the workspace digit next to them. The glyphs
  -- fill nearly the whole em box, so their optical centre sits closer to the
  -- baseline as the size shrinks -- change app_icon_size and this needs
  -- retuning with it.
  app_icon_y_offset = 0,
}
