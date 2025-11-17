local colors = require("colors")

local cpu = sbar.add("item", "widgets.cpu", {
  position = "right",
  update_freq = 2,
  icon = {
    string = "􀫥",
    color = colors.nord9,
    font = {
      style = "Semibold",
      size = 14.0,
    },
  },
  label = {
    string = "??%",
    color = colors.white,
    padding_left = 5,
    font = {
      family = "JetBrainsMono Nerd Font",
      style = "Semibold",
      size = 12.0,
    },
  },
  padding_left = 8,
  padding_right = 8,
})

cpu:subscribe("routine", function(env)
  sbar.exec("top -l 2 -n 0 -F -s 0 | grep 'CPU usage' | tail -1 | awk '{print $3}' | cut -d'%' -f1", function(cpu_usage)
    local usage = tonumber(cpu_usage)
    if usage then
      local color = colors.nord14
      if usage > 70 then
        color = colors.nord11
      elseif usage > 50 then
        color = colors.nord13
      end
      
      cpu:set({
        label = string.format("%.0f%%", usage),
        icon = { color = color }
      })
    end
  end)
end)
