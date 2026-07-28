-- SF Symbols glyphs. The font is installed via the font-sf-pro cask, which is
-- already in the Brewfile.
return {
  cpu = "􀫥",
  memory = "􀫦",
  network = {
    upload = "􀄨",
    download = "􀄩",
  },
  volume = {
    _100 = "􀊩",
    _66 = "􀊧",
    _33 = "􀊥",
    _10 = "􀊡",
    _0 = "􀊣",
  },
  battery = {
    _100 = "􀛨",
    _75 = "􀺸",
    _50 = "􀺶",
    _25 = "􀛩",
    _0 = "􀛪",
    charging = "􀢋",
  },
  -- mic.fill and mic.slash.fill. Found by rendering the private-use range
  -- around U+1002B0 out of SF Pro and reading it off; the SF Symbols app ships
  -- the names but not the codepoints.
  mic = {
    on = "\u{1002B1}",
    off = "\u{1002B3}",
  },
  wifi = {
    connected = "􀙇",
    disconnected = "􀙈",
  },
  calendar = "􀉉",
  clock = "􀐫",
}
