local icons = require("icons")
local settings = require("settings")

local memory = sbar.add("item", "widgets.memory", {
  position = "right",
  -- memoryWidgetOptions.refreshFrequency = 4000
  update_freq = 4,
  icon = { string = icons.memory },
  label = { string = "--%", width = 34, align = "right" },
  -- memoryWidgetOptions.memoryMonitorApp = "Activity Monitor"
  click_script = settings.close_popups .. "; open -a 'Activity Monitor'",
})

memory:subscribe({ "routine", "forced", "system_woke" }, function()
  -- Same command simple-bar used, so the number stays identical. It reports
  -- free percentage, hence the inversion.
  sbar.exec("memory_pressure | tail -1 | awk '{ print $5 }' | tr -d '%'",
    function(output)
      local free = tonumber(output)
      if free then
        memory:set({ label = string.format("%d%%", 100 - free) })
      end
    end)
end)
