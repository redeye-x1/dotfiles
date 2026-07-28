local icons = require("icons")
local settings = require("settings")

-- The C provider pushes cpu_update every 2 seconds, matching
-- cpuWidgetOptions.refreshFrequency = 2000 in .simplebarrc. Nothing polls.
sbar.exec("killall cpu_load >/dev/null 2>&1; "
  .. "$CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")

local cpu = sbar.add("item", "widgets.cpu", {
  position = "right",
  icon = { string = icons.cpu },
  label = { string = "--%", width = 34, align = "right" },
  click_script = settings.close_popups .. "; open -a 'Activity Monitor'",
})

cpu:subscribe("cpu_update", function(env)
  -- env also carries user_load and sys_load
  cpu:set({ label = env.total_load .. "%" })
end)
