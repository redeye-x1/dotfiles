-- Local additions to the generated app_icons.lua.
--
-- Anything in here wins over the upstream mapping, so this is the place for
-- apps sketchybar-app-font does not cover and for overriding an icon you do not
-- like. Keeping them separate means app_icons.lua can be regenerated from a
-- newer font release without losing these.
--
-- The value must be a ligature the installed font actually contains; a slug it
-- does not know renders as literal text. The available ones are the filenames
-- in the mappings/ directory of kvndrsslr/sketchybar-app-font.

return {
  -- Not in the font. A stand-in rather than a likeness: the alternatives are
  -- all named after other products (:claude:, :codex:, :cursor:), which would
  -- be worse than generic.
  ["Superset"] = ":terminal:",

  -- Pencil, the .pen design editor. The font has nothing named after a pencil or
  -- a brush, so this borrows Notability's glyph, which draws only the tool and no
  -- wordmark -- unlike the design-app alternatives (:figma: is the F, :sketch: the
  -- diamond, :illustrator: literally "Ai"). Notability is not installed here, so
  -- the glyph cannot end up on two pills at once.
  --
  -- Drawing our own glyph and merging it into the font was tried and dropped: it
  -- worked, but the font is owned by the cask, so every upgrade wiped the glyph
  -- and left the literal text ":pen:" in the pill until a script was rerun.
  ["Pen"] = ":notability:",

  -- The font has no Zoho glyph, and the app reports itself with the "- Desktop"
  -- suffix, so the upstream ["Mail"] entry never matches. Generic envelope, the
  -- same one Canary/MailMate/Spark get.
  ["Zoho Mail - Desktop"] = ":mail:",

  -- Amphetamine deliberately stays on :default:. The font has no keep-awake or
  -- caffeine glyph, and :clock: or :timery: would say the wrong thing.
}
