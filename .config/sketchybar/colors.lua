-- Nord palette, taken verbatim from the "themes" block of .simplebarrc so the
-- bar keeps the exact colours it had under simple-bar.
return {
  main = 0xff3b4252,      -- colorMain
  main_alt = 0xff2e3440,  -- colorMainAlt
  minor = 0xff4c566a,     -- colorMinor, default widget background
  accent = 0xff88c0d0,    -- colorAccent, focused workspace
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

  -- Frame of an empty workspace. nord3, the colour the pill would have been
  -- filled with, so the outline traces the shape of what is missing -- at 65%
  -- so it does not read as heavily as a filled edge would.
  --
  -- border_width is an integer in sketchybar's source, so 1.5 is not available:
  -- asking for it stores 1 without complaint. Two points at reduced opacity is
  -- how to land between the two weights.
  outline = 0xa64c566a,

  -- Digit of an empty workspace, brighter than the frame around it on purpose.
  -- Matching the frame reads as one quiet tone but leaves the number barely
  -- there: nord3 renders as #424a5b on the bar, and opacity cannot lift it,
  -- since alpha only moves a colour toward its background. White at 40% gives
  -- #7a7f88, well below the #bbc1ca of an occupied workspace.
  empty_digit = 0x66eceff4,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
