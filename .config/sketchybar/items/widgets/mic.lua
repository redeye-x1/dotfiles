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
  icon = { string = icons.mic.on },
  -- The dot marks a live microphone, so it shows on the state you want to
  -- notice. No second item needed: the label carries its own colour, so it can
  -- be red while the icon stays white.
  label = {
    string = "􀀁",
    color = colors.red,
    font = { size = 8.0 },
    drawing = false,
    padding_left = 0,
    padding_right = settings.item_padding,
    y_offset = 1,
  },
})

-- The level to come back to. Seeded from whatever the input is at when the bar
-- starts, so a mic already turned down does not get restored to full blast.
local last_level = nil

local function render(level)
  local live = level > 0
  mic:set({
    icon = {
      string = live and icons.mic.on or icons.mic.off,
      -- Muted, the icon is alone in the pill and needs even padding. With the
      -- dot beside it, this becomes the gap between the two.
      padding_right = live and 5 or settings.item_padding,
    },
    label = { drawing = live },
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
