local icons = require("icons")

-- timeWidgetOptions: hour12 = false, showSeconds = false. dayProgress was
-- dropped in the migration design.
local time = sbar.add("item", "widgets.time", {
  position = "right",
  update_freq = 1,
  icon = { string = icons.clock },
  label = { string = os.date("%H:%M"), width = 44, align = "right" },
})

time:subscribe({ "routine", "forced", "system_woke" }, function()
  time:set({ label = os.date("%H:%M") })
end)
