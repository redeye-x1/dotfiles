-- Order matters. Items with position "right" are appended leftwards, so this
-- list is the reverse of the on-screen order, which reads
-- netstats, cpu, memory, wifi, battery, sound, datetime
-- from left to right.
require("items.widgets.datetime")
require("items.widgets.sound")
require("items.widgets.battery")
require("items.widgets.wifi")
require("items.widgets.memory")
require("items.widgets.cpu")
require("items.widgets.netstats")
