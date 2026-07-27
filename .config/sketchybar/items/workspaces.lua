local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local app_icons_local = require("helpers.app_icons_local")

local WORKSPACE_COUNT = 6

local spaces = {}

-- Fired by exec-on-workspace-change in .aerospace.toml.
sbar.add("event", "aerospace_workspace_change")

local function icon_for(app)
  return app_icons_local[app] or app_icons[app] or app_icons["Default"]
end

-- One shell round trip for the whole bar: the focused workspace, a separator,
-- then every window with the workspace it lives on. Querying each workspace
-- individually would be six invocations per update.
local QUERY = "aerospace list-workspaces --focused; echo '--'; "
  .. "aerospace list-windows --all --format '%{workspace}|%{app-name}'"

local function update()
  sbar.exec(QUERY, function(output)
    if not output then return end

    local focused, seen_separator = nil, false
    local icons_by_workspace = {}
    local seen_apps = {}

    -- Lua 5.5 makes the generic-for variable const, so trim into a new local.
    for raw in output:gmatch("[^\n]+") do
      local line = raw:match("^%s*(.-)%s*$")
      if line == "--" then
        seen_separator = true
      elseif not seen_separator then
        focused = focused or line
      else
        local workspace, app = line:match("^(.-)|(.*)$")
        if workspace and app and app ~= "" then
          -- hideDuplicateAppsInSpaces = true in .simplebarrc
          local key = workspace .. "|" .. app
          if not seen_apps[key] then
            seen_apps[key] = true
            icons_by_workspace[workspace] =
              (icons_by_workspace[workspace] or "") .. icon_for(app)
          end
        end
      end
    end

    for i = 1, WORKSPACE_COUNT do
      local key = tostring(i)
      local icons = icons_by_workspace[key]
      local is_focused = focused == key

      -- Every workspace keeps the same pill the data widgets on the right have.
      -- Only the focused one stands out, via the accent colour.
      local background, foreground
      if is_focused then
        background, foreground = colors.accent, colors.black
      else
        background, foreground = colors.minor, colors.dim
      end

      spaces[i]:set({
        background = { color = background },
        icon = { color = foreground },
        label = {
          string = icons or "",
          color = foreground,
          -- An empty label still contributes its padding, which left the digit
          -- of an empty workspace looking off-centre inside its pill. Dropping
          -- the label from the layout leaves the digit framed symmetrically by
          -- the icon paddings alone.
          drawing = icons ~= nil,
        },
      })
    end
  end)
end

for i = 1, WORKSPACE_COUNT do
  spaces[i] = sbar.add("item", "space." .. i, {
    position = "left",
    background = {
      color = colors.minor,
      corner_radius = settings.item_radius,
      height = settings.space_height,
    },
    icon = {
      string = tostring(i),
      -- Unfocused is the right initial state: update() corrects it right away,
      -- and anything the colour of the pill behind it would be invisible.
      color = colors.dim,
      -- Equal on both sides so an empty workspace centres its digit. The gap to
      -- the app icons lives on the label instead, because this padding applies
      -- whether or not any icons follow.
      padding_left = 8,
      padding_right = 8,
      font = {
        family = settings.font.text,
        style = settings.font.style_map["Semibold"],
        size = 13.0,
      },
    },
    label = {
      string = "",
      color = colors.dim,
      -- Adds to the digit's padding_right of 8, so the visible gap is 12. The
      -- label is dropped from the layout on empty workspaces, so this never
      -- unbalances their pill.
      padding_left = 4,
      padding_right = 8,
      -- The style must be spelled out. sketchybar-app-font ships Regular only,
      -- and inheriting the Semibold from default.lua asks for a face that does
      -- not exist, which drops the label to a fallback font that renders the
      -- ligature as the literal text ":gear:".
      font = {
        family = settings.app_icon_font,
        style = "Regular",
        size = settings.app_icon_size,
      },
      y_offset = settings.app_icon_y_offset,
    },
    -- settings.paddings, same as the data widgets use, so the gaps between the
    -- workspace pills match the gaps on the right of the bar.
    padding_left = settings.paddings,
    padding_right = settings.paddings,
    click_script = "aerospace workspace " .. i,
  })
end

-- Everything that changes the icons pushes an update: aerospace fires
-- aerospace_workspace_change on workspace switch, on focus change, on a newly
-- detected window, and from the move-node-to-workspace bindings. Closing a
-- window has no aerospace callback, but focus leaves the closed window, so that
-- path is covered too.
--
-- The routine below is a pure backstop for whatever those miss. It is
-- deliberately slow; the icons should already be right by the time it runs.
spaces[1]:subscribe(
  { "aerospace_workspace_change", "front_app_switched", "system_woke",
    "forced", "routine" },
  update)
spaces[1]:set({ update_freq = 30 })

update()
