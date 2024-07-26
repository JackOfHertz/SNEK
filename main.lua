local push = require("lib/push")
local baton = require("lib/baton")

local lg = love.graphics
local assets = {}

local game_width, game_height = 512, 242
local window_width, window_height = love.window.getDesktopDimensions()

push:setupScreen(game_width, game_height, window_width, window_height, {
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
GRID_ROWS = 14
GRID_UNIT = math.floor(game_width / GRID_COLUMNS)
GRID_THICKNESS = math.floor(GRID_UNIT / 8)
GRID_MARGIN = GRID_THICKNESS * 0.5

BLOCK_UNIT = GRID_UNIT - GRID_THICKNESS
BLOCK_OFFSET = BLOCK_UNIT * 0.5

local snek = { { 4, 1 }, { 3, 1 }, { 2, 1 }, { 1, 1 } }

local function advance_snek(move_x, move_y)
	for i = #snek, 2, -1 do
		snek[i][1], snek[i][2] = unpack(snek[i - 1])
	end
	snek[1][1], snek[1][2] = snek[1][1] + move_x, snek[1][2] + move_y
end

local theta = 0
local time = 0

function love.resize(w, h)
	return push:resize(w, h)
end

function love.load()
	lg.setDefaultFilter("nearest", "nearest", 0)

	assets.title_font = lg.newFont("assets/fonts/joystix_monospace.otf", 20)
	assets.option_font = lg.newFont("assets/fonts/joystix_monospace.otf", 12)

	assets.simplex = lg.newImage("shaders/simplex-noise-64.png")
	assets.water_shader = lg.newShader("shaders/water.glsl")
	assets.water_shader:send("simplex", assets.simplex)

	assets.rainbow_shader = lg.newShader("shaders/rainbow.glsl")

	push:setupCanvas({
		{ name = "base_canvas" },
		{ name = "grid_canvas" },
		{ name = "snake_canvas" },
		{ name = "ui_canvas", shaders = { assets.rainbow_shader } },
	})
end

local move_x, move_y = 1, 0
local input_timer = 0

function love.update(dt)
	input:update()

	local x, y = input:get("move")
	if x ~= 0 and y ~= 0 or x == -move_x or y == -move_y then
	-- do nothing
	elseif x ~= 0 then
		move_x, move_y = x, 0
	elseif y ~= 0 then
		move_x, move_y = 0, y
	end

	if input_timer > 20 then
		advance_snek(move_x, move_y)
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
		lg.rectangle("fill", i * GRID_UNIT, GRID_MARGIN, GRID_THICKNESS, game_height - GRID_THICKNESS)
	end
	lg.setColor(0.2, 0.2, 0.4)
	for i = 0, GRID_ROWS do
		lg.rectangle("fill", 0, i * GRID_UNIT + GRID_MARGIN, game_width, GRID_THICKNESS)
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
	for i = 1, #snek do
		draw_block(unpack(snek[i]))
	end
end

local function draw_ui()
	lg.push()
	lg.setColor(1, 1, 1)
	lg.setFont(assets.title_font)
	lg.printf("SNEK", game_width * 0.5, game_height * 0.5, 80, "center", 0.15 * math.sin(theta), 1, 1, 40, 16)
	lg.setFont(assets.option_font)
	lg.printf("NEW GAME", game_width * 0.5, game_height * 0.7, 80, "center", 0, 1, 1, 40, 16)
	lg.printf("SETTINGS", game_width * 0.5, game_height * 0.8, 80, "center", 0, 1, 1, 40, 16)
	lg.printf("EXIT", game_width * 0.5, game_height * 0.9, 80, "center", 0, 1, 1, 40, 16)
	lg.pop()
end

function love.draw()
	push:start()
	push:setCanvas("base_canvas")
	lg.setColor(0.05, 0.05, 0.05)
	lg.rectangle("fill", 0, 0, game_width, game_height)

	lg.setBlendMode("alpha", "premultiplied")

	push:setCanvas("grid_canvas")
	draw_grid()

	push:setCanvas("snake_canvas")
	lg.setShader(assets.rainbow_shader)
	draw_snake()
	lg.setShader()

	-- push:setShader("ui_canvas", assets.water_shader)
	-- push:setShader("ui_canvas", assets.water_shader)
	push:setCanvas("ui_canvas")
	lg.setShader(assets.water_shader)
	draw_ui()

	push:finish()
end
