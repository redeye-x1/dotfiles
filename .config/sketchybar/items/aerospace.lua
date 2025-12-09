local colors = require("colors")

local spaces = {}

local function get_workspaces_with_windows()
  local workspaces_set = {}
  local handle = io.popen("aerospace list-workspaces --monitor all --empty no 2>/dev/null")
  if handle then
    for line in handle:lines() do
      local workspace_id = line:match("^%s*(.-)%s*$")
      if workspace_id and workspace_id ~= "" then
        workspaces_set[workspace_id] = true
      end
    end
    handle:close()
  end
  return workspaces_set
end

local function get_focused_workspace()
  local handle = io.popen("aerospace list-workspaces --focused 2>/dev/null")
  if handle then
    local result = handle:read("*l")
    handle:close()
    return result
  end
  return nil
end

local function update_all_spaces()
  local focused_workspace = get_focused_workspace()
  if not focused_workspace then
    return
  end

  local workspaces_with_windows = get_workspaces_with_windows()

  for i = 1, 6, 1 do
    local has_windows = workspaces_with_windows[tostring(i)] == true
    local is_focused = focused_workspace == tostring(i)

    local bg_color = colors.transparent
    local label_color = colors.grey

    if is_focused then
      bg_color = colors.bg2
      label_color = colors.black
    elseif has_windows then
      label_color = colors.white
    end

    spaces[i]:set({
      background = { color = bg_color },
      label = { color = label_color }
    })
  end
end

-- Create 6 workspace items
for i = 1, 6, 1 do
  local space = sbar.add("item", "space." .. i, {
    position = "left",
    background = {
      color = colors.transparent,
      border_width = 0,
      corner_radius = 5,
      height = 20,
    },
    icon = {
      drawing = false,
    },
    label = {
      string = tostring(i),
      color = colors.grey,
      width = 30,
      align = "center",
      font = {
        family = "SF Pro",
        style = "Semibold",
        size = 13.0,
      },
    },
    padding_left = 1,
    padding_right = 1,
    update_freq = 1,  -- Poll every second
    script = "",
  })

  spaces[i] = space
end

-- Subscribe only the first space to routine updates
spaces[1]:subscribe("routine", function(env)
  update_all_spaces()
end)

-- Also subscribe to aerospace events for immediate updates (best effort)
sbar.add("event", "aerospace_workspace_change")
spaces[1]:subscribe("aerospace_workspace_change", function(env)
  update_all_spaces()
end)

-- Initial update
update_all_spaces()
