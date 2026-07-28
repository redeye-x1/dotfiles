local icons = require("icons")
local settings = require("settings")
local hover = require("helpers.hover")

local battery = sbar.add("item", "widgets.battery", {
  position = "right",
  -- batteryWidgetOptions.refreshFrequency = 10000, plus the native
  -- power_source_change event so plugging in registers immediately.
  update_freq = 10,
  icon = { string = icons.battery._100 },
  label = { string = "--%", width = 34, align = "right" },
  -- No action of its own, but a click here should still dismiss a popup.
  click_script = settings.close_popups,
})

battery:subscribe({ "routine", "forced", "system_woke", "power_source_change" },
  function()
    -- Same pmset invocations simple-bar used.
    sbar.exec("pmset -g batt | egrep '([0-9]+%).*' -o --colour=auto | cut -f1 -d'%'",
      function(percent)
        local charge = tonumber(percent)
        if not charge then return end

        sbar.exec("pmset -g batt | grep -q 'AC Power' && echo yes || echo no",
          function(ac)
            local charging = ac:match("yes") ~= nil
            local icon = icons.battery._0
            if charging then
              icon = icons.battery.charging
            elseif charge > 87 then icon = icons.battery._100
            elseif charge > 62 then icon = icons.battery._75
            elseif charge > 37 then icon = icons.battery._50
            elseif charge > 12 then icon = icons.battery._25
            end

            battery:set({
              icon = { string = icon },
              label = { string = charge .. "%" },
            })
          end)
      end)
  end)

hover.attach(battery)
