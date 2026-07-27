local icons = require("icons")

local sound = sbar.add("item", "widgets.sound", {
  position = "right",
  icon = { string = icons.volume._100 },
  label = { string = "--%", width = 34, align = "right" },
})

-- One osascript invocation for both values rather than two.
local QUERY = "osascript -e 'set v to get volume settings' "
  .. "-e 'get (output volume of v as text) & \"|\" & (output muted of v as text)'"

local function render(volume, muted)
  local icon = icons.volume._0
  if not muted then
    if volume > 60 then icon = icons.volume._100
    elseif volume > 30 then icon = icons.volume._66
    elseif volume > 10 then icon = icons.volume._33
    elseif volume > 0 then icon = icons.volume._10
    end
  end
  sound:set({
    icon = { string = icon },
    label = { string = volume .. "%" },
  })
end

-- volume_change is a native sketchybar event, so this widget costs nothing
-- while the volume is not being touched. simple-bar polled it every 20s.
sound:subscribe({ "volume_change", "forced", "system_woke" }, function(env)
  local volume = tonumber(env.INFO)

  sbar.exec(QUERY, function(output)
    local level, muted = output:match("^%s*(%-?%d+)|(%a+)")
    -- The event payload is authoritative for the level when present; the query
    -- is what tells us whether output is muted.
    render(volume or tonumber(level) or 0, muted == "true")
  end)
end)
