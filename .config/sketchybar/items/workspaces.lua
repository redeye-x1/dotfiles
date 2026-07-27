local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local app_icons_local = require("helpers.app_icons_local")

local WORKSPACE_COUNT = 6

-- The app whose unread badge is mirrored into the bar. The Dock is the source:
-- it is the only place the count is exposed to other processes.
local BADGE_APP = "Slack"
local BADGE_POLL_SECONDS = 7

local workspaces = {}
local badges = {}

-- Which workspace currently holds BADGE_APP, and whether it has a badge. The
-- two are found by separate queries, so keep both and re-render on either.
local badge_workspace = nil
local badge_active = false

-- Fired by exec-on-workspace-change in .aerospace.toml.
sbar.add("event", "aerospace_workspace_change")

local function icon_for(app)
  return app_icons_local[app] or app_icons[app] or app_icons["Default"]
end

local function render_badges()
  for i = 1, WORKSPACE_COUNT do
    badges[i]:set({
      drawing = badge_active and badge_workspace == tostring(i),
    })
  end
end

-- One shell round trip for the whole bar: the focused workspace, a separator,
-- then every window with the workspace it lives on. Querying each workspace
-- individually would be six invocations per update.
local QUERY = "aerospace list-workspaces --focused; echo '--'; "
  .. "aerospace list-windows --all --format '%{workspace}|%{app-name}'"

-- The Dock exposes the badge as an accessibility attribute. It is "missing
-- value" when there is nothing unread, and the command fails harmlessly when
-- the app is not in the Dock at all.
local BADGE_QUERY = "osascript -e 'tell application \"System Events\" "
  .. "to tell process \"Dock\" to get value of attribute \"AXStatusLabel\" "
  .. "of UI element \"" .. BADGE_APP .. "\" of list 1' 2>/dev/null"

local function update()
  sbar.exec(QUERY, function(output)
    if not output then return end

    local focused, seen_separator = nil, false
    local icons_by_workspace = {}
    local seen_apps = {}
    badge_workspace = nil

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
          if app == BADGE_APP then badge_workspace = workspace end
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

      sbar.set("workspace." .. i .. ".bracket",
        { background = { color = background } })

      workspaces[i]:set({
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

    render_badges()
  end)
end

for i = 1, WORKSPACE_COUNT do
  workspaces[i] = sbar.add("item", "workspace." .. i, {
    position = "left",
    -- The bracket below draws the pill for the pair.
    background = { drawing = false },
    icon = {
      string = tostring(i),
      -- Unfocused is the right initial state: update() corrects it right away.
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
    padding_left = settings.paddings,
    -- When the badge is hidden this is the gap to the next pill; when it shows,
    -- it becomes the spacing between the app icons and the dot.
    padding_right = settings.paddings,
    click_script = "aerospace workspace " .. i,
  })

  badges[i] = sbar.add("item", "workspace." .. i .. ".badge", {
    position = "left",
    drawing = false,
    background = { drawing = false },
    icon = {
      string = "􀀁",
      color = colors.red,
      font = { size = 8.0 },
      padding_left = 0,
      padding_right = 8,
      y_offset = 1,
    },
    label = { drawing = false },
    padding_left = 0,
    padding_right = settings.paddings,
    click_script = "aerospace workspace " .. i,
  })

  -- One pill per workspace, drawn by the bracket rather than by either member,
  -- so the badge sits inside it. Padding on a bracket does not space it from
  -- its neighbours the way it does on an item, so the gaps stay on the members:
  -- both carry padding_right, and whichever is the last visible one supplies it.
  -- A bracket spans its members including their padding, and neither padding
  -- nor background.padding on the bracket separates it from the next one --
  -- both are accepted by --query but never drawn. An empty item between the
  -- brackets is what actually produces the gap.
  if i < WORKSPACE_COUNT then
    sbar.add("item", "workspace." .. i .. ".gap", {
      position = "left",
      width = settings.paddings * 2,
      background = { drawing = false },
      icon = { drawing = false },
      label = { drawing = false },
    })
  end

  sbar.add("bracket", "workspace." .. i .. ".bracket",
    { "workspace." .. i, "workspace." .. i .. ".badge" }, {
      background = {
        color = colors.minor,
        corner_radius = settings.item_radius,
        height = settings.workspace_height,
      },
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
workspaces[1]:subscribe(
  { "aerospace_workspace_change", "front_app_switched", "system_woke",
    "forced", "routine" },
  update)
workspaces[1]:set({ update_freq = 30 })

-- Dock badges emit no event, so this is the one thing in the bar that polls.
-- It is kept off the workspace update on purpose: that one runs on every focus
-- change, and an osascript round trip there would make switching feel sluggish.
--
-- updates = true matters, because the item is never drawn and the config
-- default of "when_shown" would stop it from ever running.
local badge_poll = sbar.add("item", "workspace.badge_poll", {
  position = "left",
  drawing = false,
  updates = true,
  update_freq = BADGE_POLL_SECONDS,
})

badge_poll:subscribe({ "routine", "forced", "system_woke" }, function()
  sbar.exec(BADGE_QUERY, function(output)
    local value = (output or ""):match("^%s*(.-)%s*$")
    badge_active = value ~= "" and value ~= "missing value"
    render_badges()
  end)
end)

update()
