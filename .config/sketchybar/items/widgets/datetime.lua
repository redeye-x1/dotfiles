local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Date and time in one pill, replacing the two they used to occupy. Measured
-- before the merge: 93pt for the date, 72pt for the time, plus the gap.
--
-- One item is enough because icon and label carry their own font and colour.
-- The clock glyph rides along in the icon string with the time, so the time can
-- be set in one size and the date in another without a second item.
--
-- The weighting is deliberate: the time is what gets glanced at, the date is
-- what gets consulted. Previously they were the same size, and the one that
-- matters less took the larger pill.
local datetime = sbar.add("item", "widgets.datetime", {
  position = "right",
  -- os.date runs inside the existing Lua process, so ticking every second
  -- spawns nothing. Only the minute is shown; the extra ticks just keep the
  -- rollover from lagging.
  update_freq = 1,
  icon = {
    string = icons.clock .. "  " .. os.date("%H:%M"),
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 12.0,
    },
  },
  label = {
    string = os.date("%a %d %b"),
    color = colors.dim,
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 9.0,
    },
  },
  -- dateWidgetOptions.calendarApp was empty, so this is the system default.
  click_script = settings.close_popups .. "; open -a 'Calendar'",
})

datetime:subscribe({ "routine", "forced", "system_woke" }, function()
  datetime:set({
    icon = { string = icons.clock .. "  " .. os.date("%H:%M") },
    label = os.date("%a %d %b"),
  })
end)
