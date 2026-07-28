-- Order matters. Items with position "right" are appended leftwards, so this
-- list is the reverse of the on-screen order, which is meant to read
-- netstats, cpu, memory, battery, sound, wifi, datetime from left to right
-- (the order simple-bar rendered them in, see index.jsx:262-273).
require("items.widgets.datetime")
require("items.widgets.wifi")
require("items.widgets.sound")
require("items.widgets.battery")
require("items.widgets.memory")
require("items.widgets.cpu")
require("items.widgets.netstats")
