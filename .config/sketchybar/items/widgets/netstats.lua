local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- simple-bar sampled this by running `netstat -w1` for 1.5 seconds every 2
-- seconds (lib/scripts/netstats.sh). The C provider reads the interface
-- counters directly and pushes network_update instead.
sbar.exec("killall network_load >/dev/null 2>&1; "
  .. "$CONFIG_DIR/helpers/event_providers/network_load/bin/network_load "
  .. "en0 network_update 2.0")

-- Rolling peak so the graph scales to whatever the link actually does rather
-- than to a guessed ceiling. It decays so one large download does not flatten
-- the graph for the rest of the session.
local peak = 1.0

-- The provider formats with "%03d%s", which yields zero-padded oddities like
-- "003KBps" and, for the byte unit, a stray space as in "700 Bps". Parse it back
-- to a plain byte rate and do the formatting here.
local function to_bytes(value)
  local number, unit = value:match("^(%d+)%s*(%a+)ps$")
  if not number then return 0 end
  local scale = ({ B = 1, KB = 1024, MB = 1024 * 1024 })[unit] or 1
  return tonumber(number) * scale
end

local function format_rate(bytes)
  if bytes >= 1024 * 1024 then
    return string.format("%.1fM", bytes / (1024 * 1024))
  elseif bytes >= 1024 then
    return string.format("%dK", bytes / 1024)
  end
  return string.format("%dB", bytes)
end

local netstats = sbar.add("graph", "widgets.netstats", 40, {
  position = "right",
  graph = { color = colors.with_alpha(0xffeceff4, 0.6) },
  -- The label already carries both arrows, so no separate item icon.
  icon = { drawing = false },
  label = {
    string = "--",
    width = 62,
    align = "right",
    font = { size = 9.0 },
  },
  -- No action of its own, but a click here should still dismiss a popup.
  click_script = settings.close_popups,
})

netstats:subscribe("network_update", function(env)
  local down = to_bytes(env.download)
  local up = to_bytes(env.upload)
  peak = math.max(down, peak * 0.98)
  netstats:push({ down / peak })
  netstats:set({
    label = icons.network.download .. format_rate(down)
      .. " " .. icons.network.upload .. format_rate(up),
  })
end)
