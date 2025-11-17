local wezterm = require("wezterm")
local config = wezterm.config_builder()

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

local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider

config.color_scheme = "nord"
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 16.0
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.tab_max_width = 32
config.window_background_opacity = 0.98
config.window_decorations = "RESIZE"

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
			fg_color = nord.polar_night.nord3,
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
	local background = nord.polar_night.nord0
	local foreground = nord.polar_night.nord3

	if tab.is_active then
		background = nord.frost.nord8
		foreground = nord.polar_night.nord0
	elseif hover then
		background = nord.polar_night.nord2
		foreground = nord.snow_storm.nord4
	end

	local title = tab.active_pane.title or "zsh"
	if #title > 20 then
		title = title:sub(1, 19) .. "…"
	end

	local tab_number_icons = {
		wezterm.nerdfonts.md_numeric_1_box,
		wezterm.nerdfonts.md_numeric_2_box,
		wezterm.nerdfonts.md_numeric_3_box,
		wezterm.nerdfonts.md_numeric_4_box,
		wezterm.nerdfonts.md_numeric_5_box,
		wezterm.nerdfonts.md_numeric_6_box,
		wezterm.nerdfonts.md_numeric_7_box,
		wezterm.nerdfonts.md_numeric_8_box,
		wezterm.nerdfonts.md_numeric_9_box,
	}

	local tab_icon = tab_number_icons[tab.tab_index + 1] or tostring(tab.tab_index + 1)

	return {
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = " " .. tab_icon .. " " .. title .. " " },
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

return config

