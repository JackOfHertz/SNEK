---global
--TODO: need to move
push = require("lib.push")

local baton = require("lib.baton")

require("constants")
local ui = require("ui")

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
		back = { "key:escape", "button:back" },
		confirm = { "key:return", "key:space", "key:x", "button:a" },
	},
	pairs = {
		move = { "left", "right", "up", "down" },
	},
	joystick = love.joystick.getJoysticks()[1],
})

local snek = { { 5, 1 }, { 4, 1 }, { 3, 1 }, { 2, 1 }, { 1, 1 } }
local collision = false

---advance snake state
---@param move_x number
---@param move_y number
local function advance_snek(move_x, move_y)
	local next_x, next_y = snek[1][1] + move_x, snek[1][2] + move_y
	for i = #snek, 2, -1 do
		-- update body segment locations, back to front
		snek[i][1], snek[i][2] = unpack(snek[i - 1])
		-- detect collision with self
		if next_x == snek[i][1] and next_y == snek[i][2] then
			collision = true
			return
		end
	end
	-- update head location
	snek[1][1], snek[1][2] = next_x % GRID_COLUMNS, next_y % GRID_ROWS
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
local last_input = { 1, 0 }
local move = { 1, 0 }
local snek_timer = 0

function love.update(dt)
	input:update()

	local x, y = input:get("move")
	if (x ~= 0 and y ~= 0) or (x == 0 and y == 0) or (x == -last_move[1] and y == -last_move[2]) then
		-- do nothing - prevent diagonal movement or 180 deg turn
	else
		last_input = { x, y }
	end
	move = last_input

	if not collision and snek_timer >= 0.3 then
		advance_snek(unpack(move))
		last_move = move
		snek_timer = snek_timer - 0.3
	end

	theta = theta + 0.5 * math.pi * dt
	time = time + dt
	snek_timer = snek_timer + dt

	-- update time-based shaders
	assets.water_shader:send("time", time)
	assets.rainbow_shader:send("time", time)

	ui.update(input)
end

local function draw_grid()
	lg.push()
	lg.clear(0, 0, 0, 0)
	lg.setBlendMode("alpha")
	lg.setColor(0.2, 0.2, 0.4, 0.5)
	for i = 0, GRID_COLUMNS do
		lg.rectangle("fill", i * GRID_UNIT, 0, GRID_THICKNESS, GRID_HEIGHT)
	end
	for i = 0, GRID_ROWS do
		lg.rectangle("fill", 0, i * GRID_UNIT, GRID_WIDTH, GRID_THICKNESS)
	end
	lg.pop()
end

---draw block at matrix index defined by x, y
---@param x number horizontal index
---@param y number vertical index
---@param theta? number rotation in radians
local function draw_block(x, y, theta)
	lg.push()
	lg.setColor(1, 1, 1)
	lg.translate(GRID_UNIT * x + GRID_OFFSET, GRID_UNIT * y + GRID_OFFSET)
	lg.rotate(theta and 0.15 * math.sin(2 * theta) or 0)
	lg.rectangle("fill", BLOCK_OFFSET, BLOCK_OFFSET, BLOCK_UNIT, BLOCK_UNIT)
	lg.pop()
end

---draw snake
---@param theta number
local function draw_snake(theta)
	lg.push()
	if not collision then
		lg.setShader(assets.rainbow_shader)
	end
	for i = 1, #snek do
		draw_block(snek[i][1], snek[i][2], collision and 0 or (theta - i / 5))
	end
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
	draw_snake(theta)

	-- push:setShader("ui_canvas", assets.water_shader)
	push:setCanvas("ui_canvas")
	ui.draw(theta, assets)

	push:finish()
end
