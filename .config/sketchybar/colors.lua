-- Nord palette, taken verbatim from the "themes" block of .simplebarrc so the
-- bar keeps the exact colours it had under simple-bar.
return {
  main = 0xff3b4252,      -- colorMain
  main_alt = 0xff2e3440,  -- colorMainAlt
  minor = 0xff4c566a,     -- colorMinor, default widget background
  accent = 0xff88c0d0,    -- colorAccent, focused workspace
  -- Darker accent for the digit segment of the focused workspace, so the split
  -- stays readable once the whole pill turns accent-coloured.
  accent_dark = 0xff6ba3b4,
  red = 0xffbf616a,
  green = 0xffa3be8c,
  yellow = 0xffebcb8b,
  orange = 0xffd08770,
  blue = 0xff81a1c1,
  magenta = 0xffb48ead,
  cyan = 0xff8fbcbb,
  black = 0xff2e3440,
  white = 0xffeceff4,
  foreground = 0xffeceff4,
  background = 0xff2e3440,
  transparent = 0x00000000,

  -- Digit and app icons of an unfocused workspace. White at 70% over the
  -- #4c566a pill, so the focused workspace is the only thing at full contrast.
  -- Lower the alpha byte to dim further; 0xff would be plain white again.
  dim = 0xb2eceff4,

  -- Outline of an empty workspace, which has no fill at all.
  outline = 0xff5a6478,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
