require("globals")

local next = next
local lg = love.graphics

local ui = {}

--- menu dimensions
local menu_width, menu_height = GAME_WIDTH * 0.6, GAME_HEIGHT * 0.6
local menu_offset = { (GAME_WIDTH - menu_width) * 0.5, (GAME_HEIGHT - menu_height) * 0.5 }
local menu_center = { menu_width * 0.5, menu_height * 0.5 }

---@enum menu_colors
local menu_colors = {
	background = { 0, 0, 0, 0.3 },
	active = { 1, 1, 1, 1 },
	inactive = { 1, 1, 1, 0.7 },
}

local function close_menu()
	if next(STATE.menus) then
		table.remove(STATE.menus)
	end
end

local function new_game()
	close_menu()
end

local function settings()
	table.insert(STATE.menus, SETTINGS_MENU.menu_index)
end

local function main_menu()
	STATE.paused = false
	close_menu()
	table.insert(STATE.menus, MAIN_MENU.menu_index)
end

local function pause_menu()
	table.insert(STATE.menus, PAUSE_MENU.menu_index)
end

local function exit()
	love.event.quit(0)
end

local function toggle_fullscreen()
	push:switchFullscreen(512, 288)
end

local function menu_back()
	close_menu()
end

MAIN_MENU = {
	title = "SNEK",
	menu_index = 1,
	options = {
		{ name = "NEW GAME", event = new_game },
		{ name = "SETTINGS", event = settings },
		{ name = "EXIT", event = exit },
	},
	active_index = 1,
}

SETTINGS_MENU = {
	title = "SETTINGS",
	menu_index = 2,
	options = {
		{ name = "TOGGLE FULLSCREEN", event = toggle_fullscreen },
		{ name = "BACK", event = menu_back },
	},
	active_index = 1,
}

PAUSE_MENU = {
	title = "PAUSED",
	menu_index = 3,
	options = {
		{ name = "CONTINUE", event = close_menu },
		{ name = "RESTART", event = new_game },
		{ name = "SETTINGS", event = settings },
		{ name = "QUIT", event = main_menu },
	},
	active_index = 1,
}

local menus = { MAIN_MENU, SETTINGS_MENU, PAUSE_MENU }

---confirm_buffer accounts for baton reading double inputs
-- TODO: submit bug to baton
local confirm_buffer = 0

local function update_menu(menu)
	if STATE.menus[#STATE.menus] ~= menu.menu_index then
		return
	end
	if menu.open then
		menu.open()
	end
	local down, up = input:pressed("down"), input:pressed("up")
	local confirm = input:released("confirm")
	menu.active_index = ((menu.active_index + (down and 1 or up and -1 or 0)) % #menu.options)
	if menu.active_index == 0 then
		menu.active_index = #menu.options
	end
	if confirm and confirm_buffer >= 5 then
		menu.options[menu.active_index].event()
		confirm_buffer = 0
	end
end

---draw menu
---@param theta number
---@param assets table
local function draw_menu(menu, theta, assets)
	if STATE.menus[#STATE.menus] ~= menu.menu_index then
		return
	end
	lg.push()

	-- background
	lg.setColor(menu_colors.background)
	lg.translate(unpack(menu_offset))
	lg.rectangle("fill", 0, 0, menu_width, menu_height + 0.25 * #menu.options)

	-- text
	lg.setShader(assets.water_shader)

	-- title
	lg.setFont(assets.title_font)
	lg.setColor(menu_colors.active)
	lg.printf(
		menu.title,
		menu_center[1],
		menu_height * 0.2,
		menu_width,
		"center",
		0.15 * math.sin(theta),
		1,
		1,
		menu_center[1],
		16
	)

	-- options
	lg.setFont(assets.option_font)
	for i = 1, #menu.options do
		local option = menu.options[i]
		local active = (i == menu.active_index)
		if active then
			lg.setShader(assets.water_shader)
			lg.setColor(menu_colors.active)
		else
			lg.setShader()
			lg.setColor(menu_colors.inactive)
		end
		lg.printf(
			option.name,
			menu_center[1],
			menu_height * (0.3 + 0.2 * i),
			menu_width,
			"center",
			0,
			1,
			1,
			menu_center[1],
			16
		)
	end

	-- cleanup
	lg.setShader()
	lg.pop()
end

function ui.update()
	local back = input:pressed("back")
	if not STATE.menus[1] then
		STATE.paused = back
		if STATE.paused then
			pause_menu()
		end
		return
	end
	if back and not (STATE.menus[#STATE.menus] == MAIN_MENU.menu_index) then
		close_menu()
	end
	for _, menu in ipairs(menus) do
		update_menu(menu)
	end
	confirm_buffer = confirm_buffer + 1
end

function ui.draw(theta, assets)
	for _, menu in ipairs(menus) do
		draw_menu(menu, theta, assets)
	end
end

return ui
