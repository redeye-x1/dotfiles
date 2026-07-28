local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- The volume slider used to sit in the bar, and the pill it needed came to
-- 135pt against the 62 a plain widget like cpu takes. It now lives in a popup:
-- the bar shows the level as a number, clicking opens the slider underneath.
local sound = sbar.add("item", "widgets.sound", {
  position = "right",
  icon = { string = icons.volume._100 },
  label = { string = "--%", width = 34, align = "right" },
  popup = {
    align = "center",
    y_offset = 4,
    -- Without this the row inherits the bar's 39 and the slider floats in a
    -- panel twice as tall as it needs.
    height = 26,
    background = {
      color = colors.main,
      corner_radius = settings.item_radius,
      border_width = 1,
      border_color = colors.minor,
      drawing = true,
    },
  },
})

local slider = sbar.add("slider", "widgets.sound.slider", 130, {
  position = "popup.widgets.sound",
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
  padding_left = settings.item_padding,
  padding_right = settings.item_padding,
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

-- Left click opens the slider, right click still mutes: hiding mute inside the
-- popup would make the quickest action the slowest one.
sound:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "right" then
    sbar.exec(
      "osascript -e 'set volume output muted not (output muted of (get volume settings))'",
      function() refresh(nil) end)
    return
  end
  sound:set({ popup = { drawing = "toggle" } })
end)

-- Dragging tracks the mouse but only fires once on release.
slider:subscribe("mouse.clicked", function(env)
  local percentage = tonumber(env.PERCENTAGE)
  if not percentage then return end
  -- Setting a volume on a muted output leaves it inaudible, so unmute too.
  sbar.exec("osascript -e 'set volume without output muted' "
    .. "-e 'set volume output volume " .. percentage .. "'")
end)

-- Scrolling over the widget changes the volume, which makes the popup optional
-- for the common case: the slider is only needed when aiming at a value.
-- ctrl gives single steps instead of tens.
sound:subscribe("mouse.scrolled", function(env)
  local delta = tonumber(env.INFO and env.INFO.delta) or 0
  if env.INFO and env.INFO.modifier ~= "ctrl" then delta = delta * 10 end
  if delta == 0 then return end
  sbar.exec("osascript -e 'set volume without output muted' -e 'set volume "
    .. "output volume (output volume of (get volume settings) + "
    .. delta .. ")'")
end)

-- Dismissal. sketchybar has no global click event, so this comes from two
-- directions: every other item's click_script carries settings.close_popups,
-- and switching to another application closes it here. Clicking a second
-- window of the application already in front is the one case neither covers.
--
-- Not on mouse.exited.global, though that event does fire: the popup hangs
-- below the bar, so reaching for the slider means leaving the bar and would
-- shut it just as it is being aimed at.
sound:subscribe("front_app_switched", function()
  sound:set({ popup = { drawing = "off" } })
end)
