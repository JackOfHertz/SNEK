require("constants")
require("globals")

local next = next
local lg = love.graphics

local ui = {}

local function close_menu()
	if next(STATE.menus) then
		table.remove(STATE.menus)
	end
end

function new_game()
	close_menu()
end

function settings()
	table.insert(STATE.menus, SETTINGS_MENU.menu_index)
end

function main_menu()
	table.insert(STATE.menus, MAIN_MENU.menu_index)
end

function exit()
	love.event.quit(0)
end

function toggle_fullscreen()
	push:switchFullscreen(512, 288)
end

function back()
	close_menu()
end

---main menu struct
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

---settings menu struct
SETTINGS_MENU = {
	title = "SETTINGS",
	menu_index = 2,
	options = {
		{ name = "TOGGLE FULLSCREEN", event = toggle_fullscreen },
		{ name = "BACK", event = back },
	},
	active_index = 1,
}

local menus = { MAIN_MENU, SETTINGS_MENU }

---draw menu
---@param theta number
---@param assets table
local function draw_menu(menu, theta, assets)
	if STATE.menus[#STATE.menus] ~= menu.menu_index then
		return
	end
	lg.push()

	-- background
	lg.setColor(MENU_COLORS.background)
	lg.translate(unpack(MENU_OFFSET))
	lg.rectangle("fill", 0, 0, MENU_WIDTH, MENU_HEIGHT)

	-- text
	lg.setShader(assets.water_shader)

	-- title
	lg.setFont(assets.title_font)
	lg.setColor(MENU_COLORS.active)
	lg.printf(
		menu.title,
		MENU_CENTER[1],
		MENU_HEIGHT * 0.2,
		MENU_WIDTH,
		"center",
		0.15 * math.sin(theta),
		1,
		1,
		MENU_CENTER[1],
		16
	)

	-- options
	lg.setFont(assets.option_font)
	for i = 1, #menu.options do
		local option = menu.options[i]
		local active = (i == menu.active_index)
		if active then
			lg.setShader(assets.water_shader)
			lg.setColor(MENU_COLORS.active)
		else
			lg.setShader()
			lg.setColor(MENU_COLORS.inactive)
		end
		lg.printf(
			option.name,
			MENU_CENTER[1],
			MENU_HEIGHT * (0.3 + 0.2 * i),
			MENU_WIDTH,
			"center",
			0,
			1,
			1,
			MENU_CENTER[1],
			16
		)
	end

	-- cleanup
	lg.setShader()
	lg.pop()
end

---confirm_buffer accounts for baton reading double inputs
-- TODO: submit bug to baton
local confirm_buffer = 0

local function update_menu(menu)
	if STATE.menus[#STATE.menus] ~= menu.menu_index then
		return
	end
	local down, up = input:pressed("down"), input:pressed("up")
	local confirm = input:released("confirm")
	local shift = 0
	if down then
		shift = 1
	elseif up then
		shift = -1
	end
	menu.active_index = ((menu.active_index + shift) % #menu.options)
	if menu.active_index == 0 then
		menu.active_index = #menu.options
	end
	if confirm and confirm_buffer >= 5 then
		print(confirm, "confirm")
		menu.options[menu.active_index].event()
		confirm_buffer = 0
	end
end

function ui.update(input)
	local back = input:pressed("back")
	if not STATE.menus[1] then
		if back then
			main_menu()
		end
		return
	end
	if back then
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
