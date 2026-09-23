local settings = require("settings")

-- Workaround for a macOS 27 window-ordering regression
-- (https://github.com/FelixKratz/SketchyBar/issues/850). A click that misses
-- every item lands on the bar's own window, and macOS raises it above every
-- item window: the opaque bar background then covers the whole bar until a
-- reload rebuilds the stack.
--
-- This bracket spans the full width of the bar, so a stray click lands on its
-- window instead and raises that. It draws nothing, so being raised hides
-- nothing, and sketchybar routes item clicks by cursor position, so the items
-- keep theirs.
--
-- A bracket only reaches as far as its members, and bar padding lies outside
-- every item, so the bar has no padding of its own: these two edge items stand
-- in for it. That is also why this file must load before any other item --
-- left items line up in the order they are added, right items leftwards, so
-- adding these first puts them at the outer ends. Remove the lot, and restore
-- the bar padding, once upstream fixes the ordering.
local edges = {}
for _, side in ipairs({ "left", "right" }) do
  edges[#edges + 1] = "click_shield." .. side
  sbar.add("item", "click_shield." .. side, {
    position = side,
    width = settings.bar_padding,
    padding_left = 0,
    padding_right = 0,
    background = { drawing = false },
    icon = { drawing = false },
    label = { drawing = false },
    -- The shield takes the click, so it closes popups like anything else would.
    click_script = settings.close_popups,
  })
end

sbar.add("bracket", "click_shield", edges, {
  background = {
    drawing = true,
    color = 0x00000000,
    height = settings.bar_height,
  },
})
