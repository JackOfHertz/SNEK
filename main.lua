local push = require("lib/push")

local game_width, game_height = 400, 300
local window_width, window_height = love.window.getDesktopDimensions()

local font = love.graphics.newFont("assets/fonts/joystix_monospace.otf", 20)
font:setFilter("nearest", "nearest")
love.graphics.setFont(font)

push:setupScreen(game_width, game_height, window_width, window_height, {
	canvas = true,
	fullscreen = false,
	highdpi = true,
	pixelperfect = true,
	resizable = true,
})

BLOCKS_PER_EDGE = 30
GRID_DIMENSION = math.floor(game_width / BLOCKS_PER_EDGE)
GRID_THICKNESS = math.floor(GRID_DIMENSION / 5)

BLOCK_OFFSET = GRID_THICKNESS * 0.5
BLOCK_DIMENSION = GRID_DIMENSION - GRID_THICKNESS

local theta = 0

function love.resize(w, h)
	return push:resize(w, h)
end

function love.load()
	push:setupCanvas({
		{ name = "base_canvas" },
		{ name = "grid_canvas" },
		{ name = "snake_canvas" },
		{ name = "ui_canvas" },
	})
	Snek = { { 1, 1 }, { 2, 1 }, { 3, 1 } }
end

function love.update(dt)
	theta = theta + 0.75 * math.pi * dt
end

local function draw_grid()
	-- draw static grid
	love.graphics.clear(0, 0, 0, 0)
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(0.2, 0.2, 0.5)
	for i = BLOCKS_PER_EDGE, 0, -1 do
		local line_position = i * GRID_DIMENSION - BLOCK_OFFSET
		love.graphics.rectangle("fill", 0, line_position, game_width, GRID_THICKNESS)
		love.graphics.rectangle("fill", line_position, 0, GRID_THICKNESS, game_height)
	end
end

function love.draw()
	push:start()
	push:setCanvas("base_canvas")

	love.graphics.setBlendMode("alpha", "premultiplied")

	push:setCanvas("grid_canvas")
	draw_grid()

	push:setCanvas("snake_canvas")
	love.graphics.setColor(0.6, 0.6, 0)
	love.graphics.rectangle("fill", BLOCK_OFFSET, BLOCK_OFFSET, BLOCK_DIMENSION, BLOCK_DIMENSION)

	push:setCanvas("ui_canvas")
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(
		"SNEK",
		game_width * 0.5,
		game_height * 0.5,
		80,
		"center",
		0.35 * math.sin(theta),
		1,
		1,
		40,
		16
	)

	push:finish()
end
