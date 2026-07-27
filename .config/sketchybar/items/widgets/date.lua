local icons = require("icons")

-- dateWidgetOptions: shortDateFormat = true, locale = "en-UK",
-- refreshFrequency = 30000. os.date runs inside the existing Lua process, so
-- no shell is spawned.
local date = sbar.add("item", "widgets.date", {
  position = "right",
  update_freq = 30,
  icon = { string = icons.calendar },
  label = { string = os.date("%a %d %b") },
  click_script = "open -a 'Calendar'",
})

date:subscribe({ "routine", "forced", "system_woke" }, function()
  date:set({ label = os.date("%a %d %b") })
end)
