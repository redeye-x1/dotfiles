sbar = require("sketchybar")

-- Send the whole initial configuration to sketchybar as one message instead of
-- one round trip per property.
sbar.begin_config()
require("bar")
require("default")
require("items")
sbar.end_config()

sbar.event_loop()
