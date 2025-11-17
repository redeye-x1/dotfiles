local front_app = sbar.add("item", "front_app", {
  display = "active",
  updates = true,
})

local function has_windows_in_current_workspace()
  local handle = io.popen("aerospace list-windows --workspace focused 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result and result ~= ""
  end
  return false
end

front_app:subscribe("front_app_switched", function(env)
  if has_windows_in_current_workspace() then
    front_app:set({
      label = { string = env.INFO, drawing = true },
      drawing = true
    })
  else
    front_app:set({
      label = { string = "", drawing = false },
      drawing = false
    })
  end
end)

-- Also subscribe to workspace changes to update when switching spaces
front_app:subscribe("aerospace_workspace_change", function(env)
  if has_windows_in_current_workspace() then
    -- Get the current app name
    local handle = io.popen("aerospace list-windows --workspace focused --format '%{app-name}' 2>/dev/null | head -1")
    if handle then
      local app_name = handle:read("*l")
      handle:close()
      if app_name and app_name ~= "" then
        front_app:set({
          label = { string = app_name, drawing = true },
          drawing = true
        })
      else
        front_app:set({
          label = { string = "", drawing = false },
          drawing = false
        })
      end
    end
  else
    front_app:set({
      label = { string = "", drawing = false },
      drawing = false
    })
  end
end)
