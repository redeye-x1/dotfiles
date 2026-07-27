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

  -- Amphetamine deliberately stays on :default:. The font has no keep-awake or
  -- caffeine glyph, and :clock: or :timery: would say the wrong thing.
}
