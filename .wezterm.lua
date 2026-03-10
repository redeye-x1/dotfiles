local wezterm = require("wezterm")
local config = wezterm.config_builder()
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- Enable periodic auto-save of workspace state (every 15 minutes)
resurrect.state_manager.periodic_save()

local nord = {
	polar_night = {
		nord0 = "#2E3440",
		nord1 = "#3B4252",
		nord2 = "#434C5E",
		nord3 = "#4C566A",
	},
	snow_storm = {
		nord4 = "#D8DEE9",
		nord5 = "#E5E9F0",
		nord6 = "#ECEFF4",
	},
	frost = {
		nord7 = "#8FBCBB",
		nord8 = "#88C0D0",
		nord9 = "#81A1C1",
		nord10 = "#5E81AC",
	},
}

config.color_scheme = "nord"
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 16.0
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.window_background_opacity = 0.98
config.window_decorations = "RESIZE"
config.max_fps = 120
config.animation_fps = 60
config.front_end = "WebGpu"

-- Fancy tab bar styling (Nord theme)
config.window_frame = {
	font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Bold" }),
	font_size = 14.0,
	active_titlebar_bg = nord.polar_night.nord0,
	inactive_titlebar_bg = nord.polar_night.nord0,
	active_titlebar_fg = nord.snow_storm.nord4,
	inactive_titlebar_fg = nord.polar_night.nord3,
	inactive_titlebar_border_bottom = nord.polar_night.nord0,
	active_titlebar_border_bottom = nord.polar_night.nord0,
	button_fg = nord.snow_storm.nord4,
	button_bg = nord.polar_night.nord0,
	button_hover_fg = nord.snow_storm.nord6,
	button_hover_bg = nord.polar_night.nord2,
}

-- Command palette styling (Nord theme)
config.command_palette_bg_color = nord.polar_night.nord1
config.command_palette_fg_color = nord.snow_storm.nord4
config.command_palette_font_size = 14.0

config.colors = {
	tab_bar = {
		background = nord.polar_night.nord0,
		active_tab = {
			bg_color = nord.frost.nord8,
			fg_color = nord.polar_night.nord0,
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = nord.polar_night.nord0,
			fg_color = "#9099AB",
		},
		inactive_tab_hover = {
			bg_color = nord.polar_night.nord2,
			fg_color = nord.snow_storm.nord4,
		},
		new_tab = {
			bg_color = nord.polar_night.nord0,
			fg_color = nord.snow_storm.nord4,
		},
		new_tab_hover = {
			bg_color = nord.polar_night.nord2,
			fg_color = nord.snow_storm.nord4,
		},
	},
}

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local background
	local foreground

	if tab.is_active then
		background = nord.frost.nord8
		foreground = nord.polar_night.nord0
	elseif hover then
		background = nord.polar_night.nord2
		foreground = nord.snow_storm.nord4
	else
		background = nord.polar_night.nord0
		foreground = "#9099AB"
	end

	local title = tab.active_pane.title or "zsh"
	if #title > 15 then
		title = title:sub(1, 14) .. "…"
	end

	local tab_number = tostring(tab.tab_index + 1)

	return {
		-- Number badge
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = " " .. tab_number .. " " },
		-- Title (inherits tab bar background)
		{ Foreground = { Color = foreground } },
		{ Text = " " .. title .. " " },
	}
end)

wezterm.on("update-right-status", function(window, pane)
	local elements = {}
	local cwd_uri = pane:get_current_working_dir()
	
	if cwd_uri then
		local cwd = cwd_uri.file_path
		if cwd then
			local home = os.getenv("HOME")
			if home and cwd:sub(1, #home) == home then
				cwd = "~" .. cwd:sub(#home + 1)
			end
			
			local git_branch = ""
			local git_status = ""
			
			local success, stdout = wezterm.run_child_process({
				"git",
				"-C",
				cwd_uri.file_path,
				"branch",
				"--show-current",
			})
			
			if success then
				local branch = stdout:gsub("%s+", "")
				if branch ~= "" then
					git_branch = " " .. branch
					
					local status_success, status_out = wezterm.run_child_process({
						"git",
						"-C",
						cwd_uri.file_path,
						"status",
						"--porcelain",
					})
					
					if status_success and status_out ~= "" then
						local staged = 0
						local modified = 0
						local untracked = 0
						
						for line in status_out:gmatch("[^\r\n]+") do
							local x = line:sub(1, 1)
							local y = line:sub(2, 2)
							
							if x ~= " " and x ~= "?" then
								staged = staged + 1
							end
							if y == "M" then
								modified = modified + 1
							end
							if x == "?" and y == "?" then
								untracked = untracked + 1
							end
						end
						
						local status_parts = {}
						if staged > 0 then
							table.insert(status_parts, {color = "#A3BE8C", text = "*" .. staged})
						end
						if modified > 0 then
							table.insert(status_parts, {color = "#EBCB8B", text = "!" .. modified})
						end
						if untracked > 0 then
							table.insert(status_parts, {color = nord.polar_night.nord3, text = "?" .. untracked})
						end
						
						git_status = status_parts
					end
				end
			end
			
			table.insert(elements, { Background = { Color = nord.polar_night.nord0 } })
			table.insert(elements, { Foreground = { Color = nord.frost.nord8 } })
			table.insert(elements, { Text = " \u{F07C}  " .. cwd .. "  " })
			
			if git_branch ~= "" then
				table.insert(elements, { Background = { Color = nord.polar_night.nord0 } })
				table.insert(elements, { Foreground = { Color = nord.frost.nord10 } })
				table.insert(elements, { Text = " \u{F126} " .. git_branch .. "  " })
				
				if type(git_status) == "table" and #git_status > 0 then
					for _, part in ipairs(git_status) do
						table.insert(elements, { Background = { Color = nord.polar_night.nord0 } })
						table.insert(elements, { Foreground = { Color = part.color } })
						table.insert(elements, { Text = part.text .. " " })
					end
					table.insert(elements, { Text = " " })
				end
			end
		end
	end

	window:set_right_status(wezterm.format(elements))
end)

if not config.keys then
	config.keys = {}
end

-- Add the pane navigation keybindings
table.insert(config.keys, {
	key = "h",
	mods = "CTRL|CMD",
	action = wezterm.action.ActivatePaneDirection("Left"),
})
table.insert(config.keys, {
	key = "j",
	mods = "CTRL|CMD",
	action = wezterm.action.ActivatePaneDirection("Down"),
})
table.insert(config.keys, {
	key = "k",
	mods = "CTRL|CMD",
	action = wezterm.action.ActivatePaneDirection("Up"),
})
table.insert(config.keys, {
	key = "l",
	mods = "CTRL|CMD",
	action = wezterm.action.ActivatePaneDirection("Right"),
})

-- Horizontally split pane with CTRL+SHIFT+CMD + H
table.insert(config.keys, {
	key = "h",
	mods = "CTRL|SHIFT|CMD",
	action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
})

-- Vertically split pane with CTRL+SHIFT+CMD + V
table.insert(config.keys, {
	key = "v",
	mods = "CTRL|SHIFT|CMD",
	action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
})

-- Close pane with CTRL+SHIFT+CMD + W
table.insert(config.keys, {
	key = "w",
	mods = "CTRL|SHIFT|CMD",
	action = wezterm.action.CloseCurrentPane({ confirm = true }),
})

-- Command palette (CMD + SHIFT + P)
table.insert(config.keys, {
	key = "p",
	mods = "CMD|SHIFT",
	action = wezterm.action.ActivateCommandPalette,
})

-- Resurrect: Save workspace with name prompt (CMD + SHIFT + S)
table.insert(config.keys, {
	key = "s",
	mods = "CMD|SHIFT",
	action = wezterm.action.PromptInputLine({
		description = "Enter name to save workspace as",
		action = wezterm.action_callback(function(window, pane, line)
			if line and line ~= "" then
				local state = resurrect.workspace_state.get_workspace_state()
				state.workspace = line
				resurrect.state_manager.save_state(state)
			end
		end),
	}),
})

-- Resurrect: Load workspace state (CMD + S)
table.insert(config.keys, {
	key = "s",
	mods = "CMD",
	action = wezterm.action_callback(function(win, pane)
		resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
			local type = string.match(id, "^([^/]+)") -- match before '/'
			id = string.match(id, "([^/]+)$") -- match after '/'
			id = string.match(id, "(.+)%..+$") -- remove file extension
			local opts = {
				relative = true,
				restore_text = true,
				on_pane_restore = resurrect.tab_state.default_on_pane_restore,
			}
			if type == "workspace" then
				local state = resurrect.state_manager.load_state(id, "workspace")
				resurrect.workspace_state.restore_workspace(state, opts)
			elseif type == "window" then
				local state = resurrect.state_manager.load_state(id, "window")
				resurrect.window_state.restore_window(pane:window(), state, opts)
			elseif type == "tab" then
				local state = resurrect.state_manager.load_state(id, "tab")
				resurrect.tab_state.restore_tab(pane:tab(), state, opts)
			end
		end)
	end),
})

-- Resurrect: Delete a saved state with CMD + SHIFT + D
table.insert(config.keys, {
	key = "d",
	mods = "CMD|SHIFT",
	action = wezterm.action_callback(function(win, pane)
		resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id)
			resurrect.state_manager.delete_state(id)
		end, {
			title = "Delete State",
			description = "Select State to Delete and press Enter = accept, Esc = cancel, / = filter",
			fuzzy_description = "Search State to Delete: ",
			is_fuzzy = true,
		})
	end),
})

-- Quick-select mode: select and copy URLs, paths, hashes, etc. (Cmd + Shift + Space)
table.insert(config.keys, {
	key = "Space",
	mods = "CMD|SHIFT",
	action = wezterm.action.QuickSelect,
})

-- Quick-select patterns for common items
config.quick_select_patterns = {
	-- Git short hashes (7+ hex chars)
	"[0-9a-f]{7,40}",
	-- IP addresses
	"\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}",
	-- UUIDs
	"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
}

return config

