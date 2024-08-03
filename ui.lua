require("globals")
require("util")

local next = next
local lg = love.graphics

local ui = {}

--- menu dimensions
local menu_width, menu_height = GAME.width * 0.6, GAME.height * 0.6
local menu_offset = { (GAME.width - menu_width) * 0.5, (GAME.height - menu_height) * 0.5 }
local menu_center = { menu_width * 0.5, menu_height * 0.5 }

---@enum menu_colors
local menu_colors = {
	background = { 0, 0, 0, 0.3 },
	active = { 1, 1, 1, 1 },
	inactive = { 1, 1, 1, 0.7 },
}

local function close_menu()
	if next(GAME.menus) then
		table.remove(GAME.menus)
	end
end

local function new_game()
	GAME.state = STATE.PLAY
	close_menu()
end

local function settings()
	table.insert(GAME.menus, SETTINGS_MENU.menu_index)
end

local function main_menu()
	GAME.state = STATE.MENU
	close_menu()
	table.insert(GAME.menus, MAIN_MENU.menu_index)
end

local function pause_menu()
	GAME.state = STATE.PAUSE
	table.insert(GAME.menus, PAUSE_MENU.menu_index)
end

local function exit()
	GAME.state = STATE.EXIT
	love.event.quit(0)
end

local function toggle_fullscreen()
	push:switchFullscreen(WINDOW_WIDTH, WINDOW_HEIGHT)
end

local function menu_back()
	close_menu()
end

---@class MenuOption
---@field name string
---@field callback function

---@class Menu
---@field title string
---@field menu_index number
---@field options MenuOption[]
---@field active_index number

---@type Menu
MAIN_MENU = {
	title = "SNEK",
	menu_index = 1,
	options = {
		{ name = "NEW GAME", callback = new_game },
		{ name = "SETTINGS", callback = settings },
		{ name = "EXIT", callback = exit },
	},
	active_index = 1,
}

---@type Menu
SETTINGS_MENU = {
	title = "SETTINGS",
	menu_index = 2,
	options = {
		{ name = "TOGGLE FULLSCREEN", callback = toggle_fullscreen },
		{ name = "BACK", callback = menu_back },
	},
	active_index = 1,
}

---@type Menu
PAUSE_MENU = {
	title = "PAUSED",
	menu_index = 3,
	options = {
		{ name = "CONTINUE", callback = close_menu },
		{ name = "RESTART", callback = new_game },
		{ name = "SETTINGS", callback = settings },
		{ name = "QUIT", callback = main_menu },
	},
	active_index = 1,
}

---@type Menu[]
local menus = { MAIN_MENU, SETTINGS_MENU, PAUSE_MENU }

---confirm_buffer accounts for baton reading double inputs
-- TODO: investigate further, maybe submit bug to baton
local confirm_buffer = 0

---update menu
---@param menu Menu
local function update_menu(menu)
	local down, up = input:pressed("down"), input:pressed("up")
	local confirm = input:released("confirm")
	menu.active_index = index_modulo(menu.active_index + (down and 1 or up and -1 or 0), #menu.options)
	if confirm and confirm_buffer >= 5 then
		menu.options[menu.active_index].callback()
		confirm_buffer = 0
	end
	confirm_buffer = confirm_buffer + 1
end

---draw menu
---@param menu Menu
---@param theta number
---@param assets table
local function draw_menu(menu, theta, assets)
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
			menu_height * (0.3 + (0.6 * i / #menu.options)),
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
	local back = input:released("back")
	if back then
		if GAME.state == STATE.PLAY then
			pause_menu()
		elseif GAME.state == STATE.PAUSE then
			if #GAME.menus == 1 then
				GAME.state = STATE.PLAY
			end
			close_menu()
		elseif GAME.state == STATE.MENU and #GAME.menus ~= 1 then
			close_menu()
		end
		return
	end
	if #GAME.menus ~= 0 then
		update_menu(menus[GAME.menus[#GAME.menus]])
	end
end

function ui.draw(theta, assets)
	if #GAME.menus ~= 0 then
		draw_menu(menus[GAME.menus[#GAME.menus]], theta, assets)
	end
end

return ui
