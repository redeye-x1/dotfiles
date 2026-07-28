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

  -- Outline thickness of an empty workspace. It has no fill, so 0 here makes
  -- empty workspaces disappear entirely. Thicker than the hover ring on
  -- purpose: this one is a state, that one is a transient hint.
  empty_border_width = 2,

  -- Prefixed to every click action so that clicking anything dismisses an open
  -- popup. sketchybar has no global click event, so each item has to say this
  -- for itself; the regex spares us naming them one by one.
  close_popups = "sketchybar --set '/.*/' popup.drawing=off",

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
