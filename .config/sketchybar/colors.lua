-- Nord Theme Colors
-- https://www.nordtheme.com/docs/colors-and-palettes
return {
  -- Polar Night (dark backgrounds)
  nord0 = 0xff2e3440,  -- darkest background
  nord1 = 0xff3b4252,  -- dark background
  nord2 = 0xff434c5e,  -- darker background
  nord3 = 0xff4c566a,  -- dark comments/borders

  -- Snow Storm (light foregrounds)
  nord4 = 0xffd8dee9,  -- lighter foreground
  nord5 = 0xffe5e9f0,  -- light foreground
  nord6 = 0xffeceff4,  -- lightest foreground

  -- Frost (blue/cyan accents)
  nord7 = 0xff8fbcbb,  -- cyan
  nord8 = 0xff88c0d0,  -- bright cyan
  nord9 = 0xff81a1c1,  -- blue
  nord10 = 0xff5e81ac, -- dark blue

  -- Aurora (colorful accents)
  nord11 = 0xffbf616a, -- red
  nord12 = 0xffd08770, -- orange
  nord13 = 0xffebcb8b, -- yellow
  nord14 = 0xffa3be8c, -- green
  nord15 = 0xffb48ead, -- magenta

  -- Semantic aliases
  black = 0xff2e3440,
  white = 0xffeceff4,
  red = 0xffbf616a,
  green = 0xffa3be8c,
  blue = 0xff81a1c1,
  yellow = 0xffebcb8b,
  orange = 0xffd08770,
  magenta = 0xffb48ead,
  cyan = 0xff8fbcbb,
  grey = 0xff4c566a,
  transparent = 0x00000000,

  bar = {
    bg = 0xff2e3440,      -- nord0
    border = 0xff3b4252,  -- nord1
  },
  popup = {
    bg = 0xff3b4252,      -- nord1
    border = 0xff4c566a   -- nord3
  },
  bg1 = 0x603b4252,  -- semi-transparent nord1
  bg2 = 0xff88c0d0,  -- nord8 (bright cyan) - matches WezTerm active tab

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
