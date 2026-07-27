local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Items with position "right" are appended leftwards, so the slider is added
-- first to end up to the right of the icon.
local slider = sbar.add("slider", "widgets.sound.slider", 72, {
  position = "right",
  updates = true,
  background = { drawing = false },
  slider = {
    highlight_color = colors.white,
    background = {
      height = 4,
      corner_radius = 2,
      color = colors.with_alpha(0xffeceff4, 0.25),
    },
    knob = {
      string = "􀀁",
      drawing = true,
      font = { size = 11.0 },
      color = colors.white,
    },
  },
  padding_left = 4,
  padding_right = settings.item_padding,
})

local sound = sbar.add("item", "widgets.sound", {
  position = "right",
  icon = { string = icons.volume._100, padding_right = 0 },
  label = { drawing = false },
  background = { drawing = false },
  padding_right = 0,
})

-- One pill around both, since each item draws no background of its own.
sbar.add("bracket", "widgets.sound.bracket",
  { "widgets.sound", "widgets.sound.slider" }, {
    background = {
      color = colors.minor,
      height = settings.item_height,
      corner_radius = settings.item_radius,
    },
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
  sound:set({ icon = { string = icon } })
  -- A muted output still has a volume, but showing it filled would contradict
  -- the crossed-out icon.
  slider:set({ slider = { percentage = muted and 0 or volume } })
end

local function refresh(env)
  local volume = tonumber(env and env.INFO)
  sbar.exec(QUERY, function(output)
    local level, muted = output:match("^%s*(%-?%d+)|(%a+)")
    render(volume or tonumber(level) or 0, muted == "true")
  end)
end

-- volume_change is a native sketchybar event, so this widget costs nothing
-- while the volume is not being touched. simple-bar polled it every 20s.
sound:subscribe({ "volume_change", "forced", "system_woke" }, refresh)
slider:subscribe({ "volume_change", "forced", "system_woke" }, refresh)

-- Dragging tracks the mouse continuously but only fires once on release.
slider:subscribe("mouse.clicked", function(env)
  local percentage = tonumber(env.PERCENTAGE)
  if not percentage then return end
  -- Setting a volume on a muted output leaves it inaudible, so unmute too.
  sbar.exec("osascript -e 'set volume without output muted' "
    .. "-e 'set volume output volume " .. percentage .. "'")
end)

-- Clicking the speaker toggles mute, which the slider then reflects.
sound:subscribe("mouse.clicked", function()
  sbar.exec("osascript -e 'set volume output muted not (output muted of (get volume settings))'",
    function() refresh(nil) end)
end)
