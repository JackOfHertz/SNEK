local lume = require("lib.lume")

require("globals")
require("util")

local next = next
local lg = love.graphics

local ui = {}

local function close_menu()
	if next(GAME.menus) then
		table.remove(GAME.menus)
	end
end

local function new_game()
	GAME.state = STATE.PLAY
	close_menu()
end

local function main_menu()
	GAME.state = STATE.MENU
	close_menu()
	table.insert(GAME.menus, 1)
end

local function settings()
	table.insert(GAME.menus, 2)
end

local function pause_menu()
	GAME.state = STATE.PAUSE
	table.insert(GAME.menus, 3)
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

local function continue()
	GAME.state = STATE.PLAY
	close_menu()
end

---@class MenuTemplate
---@field width number
---@field height number
---@field offset Coordinates
---@field colors table

---generate menu template
---@param width number
---@param height number
---@return MenuTemplate
local function menu_template(width, height)
	return {
		width = width,
		height = height,
		offset = { x = (GAME.width - width) * 0.5, y = (GAME.height - height) * 0.5 },
		colors = {
			background = { 0, 0, 0, 0.3 },
			active = { 1, 1, 1, 1 },
			inactive = { 1, 1, 1, 0.7 },
		},
	}
end

---@type MenuTemplate
local menu_tmpl = menu_template(GAME.width * 0.6, GAME.height * 0.6)

---@class MenuOption
---@field name string
---@field callback function

---@class Menu: MenuTemplate
---@field title string
---@field menu_index number
---@field options MenuOption[]
---@field active_index number

---@type Menu[]
local menus = {
	lume.merge(menu_tmpl, {
		title = "SNEK",
		options = {
			{ name = "NEW GAME", callback = new_game },
			{ name = "SETTINGS", callback = settings },
			{ name = "EXIT", callback = exit },
		},
		active_index = 1,
	}),
	lume.merge(menu_tmpl, {
		title = "SETTINGS",
		options = {
			{ name = "TOGGLE FULLSCREEN", callback = toggle_fullscreen },
			{ name = "BACK", callback = menu_back },
		},
		active_index = 1,
	}),
	lume.merge(menu_tmpl, {
		title = "PAUSED",
		options = {
			{ name = "CONTINUE", callback = continue },
			{ name = "RESTART", callback = new_game },
			{ name = "SETTINGS", callback = settings },
			{ name = "QUIT", callback = main_menu },
		},
		active_index = 1,
	}),
}

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
---@param assets table
local function draw_menu(menu, assets)
	lg.push()

	-- background
	lg.setColor(menu.colors.background)
	lg.translate(menu.offset.x, menu.offset.y)
	lg.rectangle("fill", 0, 0, menu.width, menu.height + 0.25 * #menu.options)

	-- text
	lg.setShader(assets.water_shader)

	-- title
	lg.setFont(assets.title_font)
	lg.setColor(menu.colors.active)

	lg.printf(
		menu.title,
		menu.width * 0.5,
		menu.height * 0.2,
		menu.width,
		"center",
		0.15 * math.sin(GAME.time),
		1,
		1,
		menu.width * 0.5,
		16
	)

	-- options
	lg.setFont(assets.option_font)
	for i = 1, #menu.options do
		local option = menu.options[i]
		local active = (i == menu.active_index)
		if active then
			lg.setShader(assets.water_shader)
			lg.setColor(menu.colors.active)
		else
			lg.setShader()
			lg.setColor(menu.colors.inactive)
		end
		lg.printf(
			option.name,
			menu.width * 0.5,
			menu.height * (0.3 + (0.6 * i / #menu.options)),
			menu.width,
			"center",
			0,
			1,
			1,
			menu.width * 0.5,
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
		elseif #GAME.menus > 1 then
			close_menu()
		elseif GAME.state == STATE.PAUSE then
			continue()
			return
		end
		return
	end
	if #GAME.menus > 0 then
		update_menu(menus[GAME.menus[#GAME.menus]])
	end
end

function ui.draw(assets)
	if #GAME.menus > 0 then
		draw_menu(menus[GAME.menus[#GAME.menus]], assets)
	end
end

return ui
