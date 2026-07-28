local colors = require("colors")

-- Fades a ring in around an item while the pointer is over it, so the bar shows
-- what can be clicked instead of leaving you to guess.
--
-- Only the border is touched, never the fill. The fill carries state -- accent
-- for the focused workspace, red for a live microphone, nothing at all for an
-- empty workspace -- and a hover effect writing to it would have to know all of
-- that to put it back.
--
-- Only the alpha moves, not the colour. sbar.animate silently does nothing when
-- handed a whole colour value; it interpolates numbers, so the ring has to be
-- the resting colour all along and merely become visible. That is also why
-- Felix Kratz's own config animates `{ alpha = ... }` everywhere and never a
-- colour outright.
local M = {}

local VISIBLE = 0.5
local FRAMES = 12

-- Set on every item in default.lua so a hover only changes alpha and can never
-- shift the layout.
M.ring = colors.with_alpha(0xffeceff4, 0.0)

function M.attach(item)
  item:subscribe("mouse.entered", function()
    sbar.animate("tanh", FRAMES, function()
      item:set({ background = { border_color = { alpha = VISIBLE } } })
    end)
  end)

  item:subscribe("mouse.exited", function()
    sbar.animate("tanh", FRAMES, function()
      item:set({ background = { border_color = { alpha = 0.0 } } })
    end)
  end)
end

return M
