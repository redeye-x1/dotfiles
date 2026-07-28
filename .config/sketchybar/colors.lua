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

  -- Frame and digit of an empty workspace, both on this one value so the whole
  -- thing recedes as a single tone.
  --
  -- White at 40% rather than nord3, which would have been the tidier idea --
  -- the outline tracing the colour the pill would have been filled with. nord3
  -- is simply too dark for a digit on the bar: it renders as #424a5b even at
  -- full opacity, and no amount of alpha lifts it, since alpha only moves it
  -- toward the background. This lands at #7a7f88, a clear step up while staying
  -- far below the #bbc1ca of an occupied workspace.
  --
  -- Note for the frame: border_width is an integer in sketchybar's source, so
  -- 1.5 is not available -- asking for it stores 1 without complaint. Two
  -- points at reduced opacity is how to land between the two weights.
  outline = 0x66eceff4,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
