local colors = require("colors")

local wifi = sbar.add("item", "widgets.wifi", {
  position = "right",
  update_freq = 10,
  icon = {
    string = "􀙇",
    color = colors.nord7,
    font = {
      style = "Semibold",
      size = 14.0,
    },
  },
  label = {
    string = "Loading...",
    color = colors.white,
    font = {
      family = "JetBrainsMono Nerd Font",
      style = "Semibold",
      size = 12.0,
    },
  },
  padding_left = 8,
  padding_right = 8,
})

wifi:subscribe("routine", function(env)
  -- Use system_profiler which works on all macOS versions
  sbar.exec("/usr/sbin/system_profiler SPAirPortDataType 2>/dev/null | awk -F': ' '/Current Network Information:/ {flag=1; next} flag && /SSID:/ {print $2; exit}'", function(ssid)
    if ssid and ssid ~= "" and #ssid > 0 then
      -- WiFi connection found
      local display_name = ssid
      if #ssid > 20 then
        display_name = ssid:sub(1, 17) .. "..."
      end
      
      wifi:set({
        icon = {
          string = "􀙇",
          color = colors.nord7,
        },
        label = display_name,
      })
    else
      -- Fallback: check if we have network connectivity
      sbar.exec("ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 && echo 'connected' || echo 'disconnected'", function(status)
        if status and status:match("connected") then
          wifi:set({
            icon = {
              string = "􀙇",
              color = colors.nord7,
            },
            label = "Connected",
          })
        else
          wifi:set({
            icon = {
              string = "􀙈",
              color = colors.nord3,
            },
            label = "No Network",
          })
        end
      end)
    end
  end)
end)
