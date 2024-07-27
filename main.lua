local push = require("lib/push")
local baton = require("lib/baton")
require("constants")

local lg = love.graphics
local assets = {}

local window_width, window_height = love.window.getDesktopDimensions()

push:setupScreen(GAME_WIDTH, GAME_HEIGHT, window_width, window_height, {
	canvas = true,
	fullscreen = false,
	highdpi = true,
	pixelperfect = true,
	resizable = true,
})

local input = baton.new({
	controls = {
		left = { "key:left", "key:a", "axis:leftx-", "button:dpleft" },
		right = { "key:right", "key:d", "axis:leftx+", "button:dpright" },
		up = { "key:up", "key:w", "axis:lefty-", "button:dpup" },
		down = { "key:down", "key:s", "axis:lefty+", "button:dpdown" },
		action = { "key:x", "button:a" },
	},
	pairs = {
		move = { "left", "right", "up", "down" },
	},
	joystick = love.joystick.getJoysticks()[1],
})

GRID_COLUMNS = 30
GRID_ROWS = 16
GRID_UNIT = math.floor(GAME_WIDTH / GRID_COLUMNS)
GRID_THICKNESS = math.floor(GRID_UNIT / 8)
GRID_MARGIN = GRID_THICKNESS * 0.5

BLOCK_UNIT = GRID_UNIT - GRID_THICKNESS
BLOCK_OFFSET = BLOCK_UNIT * 0.5

local snek = { { 5, 1 }, { 4, 1 }, { 3, 1 }, { 2, 1 }, { 1, 1 } }
local collision = false

---@param move_x number
---@param move_y number
local function advance_snek(move_x, move_y)
	local next_x, next_y = snek[1][1] + move_x, snek[1][2] + move_y
	-- detect collision with self
	for i = 2, #snek do
		if next_x == snek[i - 1][1] and next_y == snek[i - 1][2] then
			collision = true
			return
		end
	end
	-- update body segment locations, back to front
	for i = #snek, 2, -1 do
		snek[i][1], snek[i][2] = unpack(snek[i - 1])
	end
	-- update head location
	snek[1][1], snek[1][2] = next_x, next_y
end

local theta = 0
local time = 0

function love.resize(w, h)
	return push:resize(w, h)
end

function love.load()
	lg.setDefaultFilter("nearest", "nearest", 0)
	lg.setBlendMode("alpha", "premultiplied")

	assets.title_font = lg.newFont("assets/fonts/joystix_monospace.otf", 24)
	assets.option_font = lg.newFont("assets/fonts/joystix_monospace.otf", 12)

	assets.simplex = lg.newImage("shaders/simplex-noise-64.png")
	assets.water_shader = lg.newShader("shaders/water.glsl")
	assets.water_shader:send("simplex", assets.simplex)

	assets.rainbow_shader = lg.newShader("shaders/rainbow.glsl")

	push:setupCanvas({
		{ name = "base_canvas" },
		{ name = "grid_canvas" },
		{ name = "snake_canvas" },
		{ name = "ui_canvas" },
	})
end

local last_move = { 1, 0 }
local move = { 1, 0 }
local input_timer = 0

function love.update(dt)
	input:update()

	local x, y = input:get("move")
	if x ~= 0 and y ~= 0 or x == -last_move[1] or y == -last_move[2] then
	-- do nothing - prevent diagonal movement or 180 deg turn
	elseif x ~= 0 then
		move = { x, 0 }
	elseif y ~= 0 then
		move = { 0, y }
	end

	if not collision and input_timer > 20 then
		advance_snek(unpack(move))
		last_move = move
		input_timer = 0
	end
	input_timer = input_timer + 1

	theta = theta + 0.5 * math.pi * dt
	time = time + dt
	assets.water_shader:send("time", time)
	assets.rainbow_shader:send("time", time)
end

local function draw_grid()
	lg.push()
	lg.clear(0, 0, 0, 0)
	lg.setBlendMode("alpha")
	lg.setColor(0.2, 0.2, 0.4)
	for i = 0, GRID_COLUMNS do
		lg.rectangle("fill", i * GRID_UNIT, GRID_MARGIN, GRID_THICKNESS, GAME_HEIGHT - GRID_THICKNESS)
	end
	lg.setColor(0.2, 0.2, 0.4)
	for i = 0, GRID_ROWS do
		lg.rectangle("fill", 0, i * GRID_UNIT + GRID_MARGIN, GAME_WIDTH, GRID_THICKNESS)
	end
	lg.pop()
end

local function draw_block(x, y)
	lg.push()
	lg.setColor(1, 1, 1)
	lg.translate(GRID_UNIT * x, GRID_UNIT * y + GRID_MARGIN)
	-- lg.rotate(0.15 * math.sin(2 * theta))
	lg.rectangle("fill", GRID_THICKNESS, GRID_THICKNESS, BLOCK_UNIT, BLOCK_UNIT)
	lg.pop()
end

local function draw_snake()
	if not collision then
		lg.setShader(assets.rainbow_shader)
	end
	for i = 1, #snek do
		draw_block(unpack(snek[i]))
	end
	lg.setShader()
end

local function draw_ui()
	lg.push()
	lg.setColor(MENU_BACKGROUND)
	lg.translate(unpack(MENU_OFFSET))
	lg.rectangle("fill", 0, 0, MENU_WIDTH, MENU_HEIGHT)
	lg.setShader(assets.water_shader)
	lg.setColor(MENU_ACTIVE)
	lg.setFont(assets.title_font)
	lg.printf("SNEK", MENU_CENTER[1], MENU_HEIGHT * 0.2, 80, "center", 0.15 * math.sin(theta), 1, 1, 40, 16)
	lg.setColor(MENU_INACTIVE)
	lg.setFont(assets.option_font)
	lg.printf("NEW GAME", MENU_CENTER[1], MENU_HEIGHT * 0.5, 80, "center", 0, 1, 1, 40, 16)
	lg.printf("SETTINGS", MENU_CENTER[1], MENU_HEIGHT * 0.7, 80, "center", 0, 1, 1, 40, 16)
	lg.printf("EXIT", MENU_CENTER[1], MENU_HEIGHT * 0.9, 80, "center", 0, 1, 1, 40, 16)
	lg.setShader()
	lg.pop()
end

function love.draw()
	push:start()
	push:setCanvas("base_canvas")
	lg.setColor(0.05, 0.05, 0.05)
	lg.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

	push:setCanvas("grid_canvas")
	draw_grid()

	push:setCanvas("snake_canvas")
	draw_snake()

	-- push:setShader("ui_canvas", assets.water_shader)
	push:setCanvas("ui_canvas")
	draw_ui()

	push:finish()
end
