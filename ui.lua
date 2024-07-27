require("constants")

local next = next
local lg = love.graphics

local ui = {}

local function close_menu()
	if next(STATE.menus) then
		table.remove(STATE.menus)
	end
end

function love.handlers.new_game()
	close_menu()
end

function love.handlers.exit()
	love.event.quit(0)
end

function ui.draw(theta, assets)
	if STATE.menus[#STATE.menus] == MENUS.MAIN then
		ui.draw_main_menu(theta, assets)
	end
end

--- main menu struct
MAIN_MENU = {
	title = "SNEK",
	options = {
		{ name = "NEW GAME", selected = true, event = "new_game" },
		{ name = "SETTINGS", selected = false, event = "settings" },
		{ name = "EXIT", selected = false, event = "exit" },
	},
}

---draw main menu
---@param theta number
---@param assets table
function ui.draw_main_menu(theta, assets)
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
	lg.printf("SNEK", MENU_CENTER[1], MENU_HEIGHT * 0.2, 80, "center", 0.15 * math.sin(theta), 1, 1, 40, 16)

	-- options
	lg.setFont(assets.option_font)
	for i = 1, #MAIN_MENU.options do
		local option = MAIN_MENU.options[i]
		if option.selected then
			lg.setColor(MENU_COLORS.active)
		else
			lg.setColor(MENU_COLORS.inactive)
		end
		lg.printf(option.name, MENU_CENTER[1], MENU_HEIGHT * (0.3 + 0.2 * i), 80, "center", 0, 1, 1, 40, 16)
	end

	-- cleanup
	lg.setShader()
	lg.pop()
end

return ui
