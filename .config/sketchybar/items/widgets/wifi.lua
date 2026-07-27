local icons = require("icons")
local settings = require("settings")

-- macOS 14+ redacts the SSID for processes without Location Services
-- authorization, and the check runs against the calling binary rather than its
-- parent, so no amount of permission on sketchybar itself would help. The way
-- out is `sudo ipconfig sethidewifiinfo 0`, which turns the redaction off
-- system-wide -- see the note in install.sh.
--
-- ipconfig is the only one of the usual commands that honours it. system_profile
-- and networksetup keep returning <redacted> either way, which is why this does
-- not use them.
--
-- The name is treated as optional throughout: the flag is an undocumented
-- runtime setting and looks like it does not survive a reboot, so when the SSID
-- comes back redacted the widget quietly falls back to the icon alone rather
-- than putting "<redacted>" in the bar.
local wifi = sbar.add("item", "widgets.wifi", {
  position = "right",
  icon = { string = icons.wifi.connected },
  label = { drawing = false, max_chars = 18, scroll_texts = true },
  click_script = "open 'x-apple.systempreferences:com.apple.wifi-settings-extension'",
})

-- One shell round trip for both the link state and the name. The awk anchors on
-- a line starting with SSID so it does not match BSSID.
local QUERY = "ifconfig en0 2>/dev/null | grep -c 'status: active'; "
  .. "ipconfig getsummary en0 2>/dev/null | awk -F' : ' '/^ *SSID :/ {print $2; exit}'"

-- wifi_change is native, so this costs nothing between state changes.
wifi:subscribe({ "wifi_change", "forced", "system_woke" }, function()
  sbar.exec(QUERY, function(output)
    local lines = {}
    for line in output:gmatch("[^\n]+") do
      lines[#lines + 1] = line:match("^%s*(.-)%s*$")
    end

    local active = (tonumber(lines[1]) or 0) > 0
    local ssid = lines[2]
    if ssid == "" or ssid == "<redacted>" then ssid = nil end

    local show_name = active and ssid ~= nil

    wifi:set({
      icon = {
        string = active and icons.wifi.connected or icons.wifi.disconnected,
        -- With no name to show this is the only element in the pill, so it
        -- needs the same padding on both sides to sit centred. With a name, the
        -- default 5 is the gap to it.
        padding_right = show_name and 5 or settings.item_padding,
      },
      label = {
        string = ssid or "",
        drawing = show_name,
      },
    })
  end)
end)
