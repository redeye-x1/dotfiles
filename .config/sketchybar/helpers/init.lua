-- Add the SbarLua module to the package cpath
local home = os.getenv("HOME")
package.cpath = package.cpath .. ";" .. home .. "/.local/share/sketchybar_lua/?.so"

-- Build the C event providers. Upstream discards make's output here, but a
-- silent failure leaves the bar without CPU and network data and no hint as to
-- why, so let make talk and say something if it did not succeed.
local ok = os.execute("cd '" .. home .. "/.config/sketchybar/helpers' && make")
if not ok then
  io.stderr:write("sketchybar: building helpers/event_providers failed, "
    .. "cpu and network widgets will stay empty\n")
end
