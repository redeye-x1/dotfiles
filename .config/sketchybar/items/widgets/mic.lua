local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Microphone mute, as a button rather than a readout: icon only, click toggles.
--
-- macOS has no "input muted" flag the way it has one for output -- `get volume
-- settings` returns output muted and nothing equivalent for the input. Muting
-- therefore means setting the input volume to zero and putting the old level
-- back on unmute.
local RESTORE_DEFAULT = 75

local mic = sbar.add("item", "widgets.mic", {
  position = "right",
  -- No event exists for input volume, so this is a slow backstop. Muting from
  -- another app -- Zoom, Slack -- shows up here within the interval; muting
  -- from this button is immediate.
  update_freq = 15,
  icon = { string = icons.mic.on, padding_right = settings.item_padding },
  label = { drawing = false },
})

-- The level to come back to. Seeded from whatever the input is at when the bar
-- starts, so a mic already turned down does not get restored to full blast.
local last_level = nil

-- A live microphone turns the whole pill red. It is the loudest thing in the
-- bar, which is the point: everything else here reports, this one warns.
--
-- Swap colors.red for colors.minor here and set the icon colour to red instead
-- if that turns out to be too much -- the signal is the same, only quieter.
local function render(level)
  local live = level > 0
  mic:set({
    icon = { string = live and icons.mic.on or icons.mic.off },
    background = { color = live and colors.red or colors.minor },
  })
  if live then last_level = level end
end

local function refresh()
  sbar.exec("osascript -e 'input volume of (get volume settings)'",
    function(output)
      local level = tonumber(output)
      if level then render(level) end
    end)
end

mic:subscribe({ "routine", "forced", "system_woke", "front_app_switched" },
  refresh)

mic:subscribe("mouse.clicked", function()
  sbar.exec("osascript -e 'input volume of (get volume settings)'",
    function(output)
      local level = tonumber(output) or 0
      local target = 0
      if level == 0 then
        target = last_level or RESTORE_DEFAULT
      else
        last_level = level
      end
      sbar.exec("osascript -e 'set volume input volume " .. target .. "'",
        function() render(target) end)
    end)
end)
