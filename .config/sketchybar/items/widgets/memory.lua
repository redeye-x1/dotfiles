local colors = require("colors")

local memory = sbar.add("item", "widgets.memory", {
  position = "right",
  update_freq = 5,
  icon = {
    string = "􀫦",
    color = colors.nord8,
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

memory:subscribe("routine", function(env)
  sbar.exec("memory_pressure | grep 'System-wide memory free percentage:' | awk '{print 100-$5}' | cut -d'%' -f1", function(mem_used)
    local usage = tonumber(mem_used)
    if usage then
      local color = colors.nord14
      if usage > 80 then
        color = colors.nord11
      elseif usage > 60 then
        color = colors.nord13
      end
      
      memory:set({
        label = string.format("%.0f%%", usage),
        icon = { color = color }
      })
    else
      sbar.exec("vm_stat | awk '/Pages active/ {active=$3} /Pages wired/ {wired=$4} /Pages free/ {free=$3} END {gsub(/\\./, \"\", active); gsub(/\\./, \"\", wired); gsub(/\\./, \"\", free); used=(active+wired)*4096/1024/1024/1024; total=`sysctl -n hw.memsize`/1024/1024/1024; printf \"%.0f\", (used/total)*100}'", function(fallback_usage)
        local fb_usage = tonumber(fallback_usage)
        if fb_usage then
          local color = colors.nord14
          if fb_usage > 80 then
            color = colors.nord11
          elseif fb_usage > 60 then
            color = colors.nord13
          end
          
          memory:set({
            label = string.format("%.0f%%", fb_usage),
            icon = { color = color }
          })
        end
      end)
    end
  end)
end)
