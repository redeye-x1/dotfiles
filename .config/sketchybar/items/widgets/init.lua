-- Order matters. Items with position "right" are appended leftwards, so this
-- list is the reverse of the on-screen order, which is meant to read
-- netstats, cpu, memory, sound, wifi, battery, datetime from left to right
-- (simple-bar's order, index.jsx:262-273, except that battery has moved
-- next to the clock.)
require("items.widgets.datetime")
require("items.widgets.battery")
require("items.widgets.wifi")
require("items.widgets.sound")
require("items.widgets.memory")
require("items.widgets.cpu")
require("items.widgets.netstats")
