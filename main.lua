local push = require("lib/push")
local baton = require("lib/baton")

local assets = {}

local game_width, game_height = 400, 300
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

BLOCKS_PER_EDGE = 30
GRID_DIMENSION = math.floor(game_width / BLOCKS_PER_EDGE)
GRID_THICKNESS = math.floor(GRID_DIMENSION / 5)

BLOCK_OFFSET = GRID_THICKNESS * 0.5
BLOCK_DIMENSION = GRID_DIMENSION - GRID_THICKNESS
BLOCK_CENTER = BLOCK_DIMENSION * 0.5

local theta = 0
local time = 0

function love.resize(w, h)
	return push:resize(w, h)
end

function love.load()
	local font = love.graphics.newFont("assets/fonts/joystix_monospace.otf", 20)
	font:setFilter("nearest", "nearest")
	love.graphics.setFont(font)

	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	assets.simplex = love.graphics.newImage("shaders/simplex-noise-64.png")
	assets.water_shader = love.graphics.newShader("shaders/water.glsl")
	assets.water_shader:send("simplex", assets.simplex)

	push:setupCanvas({
		{ name = "base_canvas" },
		{ name = "grid_canvas" },
		{ name = "snake_canvas" },
		{ name = "ui_canvas" },
	})

	effect = love.graphics.newShader([[
  extern number time;
  vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
  {
    return vec4((1.0+sin(time))/2.0, abs(cos(time)), abs(sin(time)), 1.0);
  }
  ]])
end

local move_x, move_y = 1, 0
local input_timer = 0

function love.update(dt)
	input:update()

	local x, y = input:get("move")
	if x ~= 0 then
		move_x = x
		move_y = 0
	elseif y ~= 0 then
		move_x = 0
		move_y = y
	end

	if input_timer > 10 then
		-- move in move_direction
		input_timer = 0
	end

	theta = theta + 0.75 * math.pi * dt
	time = time + dt
	assets.water_shader:send("time", time)
	effect:send("time", time)
end

local function draw_grid()
	love.graphics.push()
	love.graphics.clear(0, 0, 0, 0)
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(0.2, 0.2, 0.5)
	for i = BLOCKS_PER_EDGE, 0, -1 do
		local line_position = i * GRID_DIMENSION - BLOCK_OFFSET
		love.graphics.rectangle("fill", 0, line_position, game_width, GRID_THICKNESS)
		love.graphics.rectangle("fill", line_position, 0, GRID_THICKNESS, game_height)
	end
	love.graphics.pop()
end

local function draw_block(x, y)
	love.graphics.push()
	love.graphics.setColor(0.7, 0.7, 0)
	love.graphics.translate(GRID_DIMENSION * (x + 0.5), GRID_DIMENSION * (y + 0.5))
	love.graphics.rotate(0.15 * math.sin(theta))
	love.graphics.rectangle("fill", -BLOCK_CENTER, -BLOCK_CENTER, BLOCK_DIMENSION, BLOCK_DIMENSION)
	love.graphics.pop()
end

local function draw_snake()
	draw_block(0, 0)
	draw_block(1, 0)
	draw_block(2, 0)
end

function love.draw()
	push:start()
	push:setCanvas("base_canvas")

	love.graphics.setBlendMode("alpha", "premultiplied")

	push:setCanvas("grid_canvas")
	draw_grid()

	love.graphics.setShader(effect)
	push:setCanvas("snake_canvas")
	draw_snake()

	love.graphics.setShader(assets.water_shader)
	push:setCanvas("ui_canvas")
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(
		"SNEK",
		game_width * 0.5,
		game_height * 0.5,
		80,
		"center",
		0.15 * math.sin(theta),
		1,
		1,
		40,
		16
	)

	push:finish()
end
