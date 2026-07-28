local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- CPU and memory in one pill. They were two, 62 and 63 points plus the gap
-- between them, and they answer the same question -- how busy is this machine.
--
-- Three items and a bracket rather than one item: an item has only an icon and
-- a label to put text in, and this needs four pieces plus a separator that
-- wants its own colour. The bracket draws the pill around them.
--
-- Items are appended leftwards at position "right", so this reads
-- cpu | memory on screen despite being built in the other order.

-- A bracket swallows the padding of its members, so their own padding would end
-- up inside the pill instead of separating it from the neighbouring widget.
-- These two spacers sit outside the bracket and restore the 6pt gap the rest of
-- the bar uses: 3 from here, 3 from the neighbour's own padding.
local function spacer(name)
  sbar.add("item", name, {
    position = "right",
    width = settings.paddings,
    background = { drawing = false },
    icon = { drawing = false },
    label = { drawing = false },
  })
end

spacer("widgets.system.gap_right")

local memory = sbar.add("item", "widgets.memory", {
  position = "right",
  -- memoryWidgetOptions.refreshFrequency = 4000
  update_freq = 4,
  background = { drawing = false },
  -- No item padding on any bracket member: it would land inside the pill. The
  -- outer air comes from the spacers, the inner from the separator below.
  padding_left = 0,
  padding_right = 0,
  icon = { string = icons.memory, padding_left = 0 },
  label = { string = "--%", width = 34, align = "right", padding_right = 9 },
  click_script = "open -a 'Activity Monitor'",
})

sbar.add("item", "widgets.system.separator", {
  position = "right",
  background = { drawing = false },
  padding_left = 0,
  padding_right = 0,
  icon = {
    string = "|",
    color = colors.with_alpha(0xffeceff4, 0.25),
    padding_left = 7,
    padding_right = 7,
  },
  label = { drawing = false },
})

local cpu = sbar.add("item", "widgets.cpu", {
  position = "right",
  background = { drawing = false },
  padding_left = 0,
  padding_right = 0,
  icon = { string = icons.cpu, padding_left = 9 },
  label = { string = "--%", width = 34, align = "right", padding_right = 0 },
  click_script = "open -a 'Activity Monitor'",
})

spacer("widgets.system.gap_left")

sbar.add("bracket", "widgets.system", {
  "widgets.cpu", "widgets.system.separator", "widgets.memory",
}, {
  background = {
    color = colors.minor,
    corner_radius = settings.item_radius,
    height = settings.item_height,
  },
})

-- The C provider pushes cpu_update every 2 seconds, matching
-- cpuWidgetOptions.refreshFrequency = 2000 in .simplebarrc. Nothing polls.
sbar.exec("killall cpu_load >/dev/null 2>&1; "
  .. "$CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")

cpu:subscribe("cpu_update", function(env)
  -- env also carries user_load and sys_load
  cpu:set({ label = env.total_load .. "%" })
end)

memory:subscribe({ "routine", "forced", "system_woke" }, function()
  -- Same command simple-bar used, so the number stays identical. It reports
  -- free percentage, hence the inversion.
  sbar.exec("memory_pressure | tail -1 | awk '{ print $5 }' | tr -d '%'",
    function(output)
      local free = tonumber(output)
      if free then
        memory:set({ label = string.format("%d%%", 100 - free) })
      end
    end)
end)
