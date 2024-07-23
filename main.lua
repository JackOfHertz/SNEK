local push = require("lib/push")

local gameWidth, gameHeight = 400, 300
local windowWidth, windowHeight = love.window.getDesktopDimensions()

push:setupScreen(gameWidth, gameHeight, windowWidth, windowHeight, {
	canvas = true,
	fullscreen = false,
	highdpi = true,
	pixelperfect = true,
	resizable = true,
})

BLOCKS_PER_EDGE = 20
GRID_DIMENSION = gameWidth / BLOCKS_PER_EDGE
GRID_THICKNESS = GRID_DIMENSION / 15

BLOCK_OFFSET = GRID_THICKNESS * 0.5
BLOCK_DIMENSION = GRID_DIMENSION - GRID_THICKNESS

function love.resize(w, h)
	return push:resize(w, h)
end

function love.load()
	push:setupCanvas({ { name = "grid_canvas" } })
	Snek = { { 1, 1 }, { 2, 1 }, { 3, 1 } }
end

function love.update()
	-- w = w + 1
	-- h = h + 1
end

local function draw_grid()
	-- draw static grid
	love.graphics.clear(0, 0, 0, 0)
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(0.2, 0.2, 0.5)
	for i = BLOCKS_PER_EDGE, 0, -1 do
		local line_position = i * GRID_DIMENSION - BLOCK_OFFSET
		love.graphics.rectangle("fill", 0, line_position, gameWidth, GRID_THICKNESS)
		love.graphics.rectangle("fill", line_position, 0, GRID_THICKNESS, gameHeight)
	end
end

function love.draw()
	push:start()
	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.setColor(1, 1, 1, 1)

	push:setCanvas("grid_canvas")
	draw_grid()

	love.graphics.setColor(0, 0.4, 0.4)
	love.graphics.rectangle("fill", BLOCK_OFFSET, BLOCK_OFFSET, BLOCK_DIMENSION, BLOCK_DIMENSION)
	love.graphics.rectangle("fill", BLOCK_OFFSET, BLOCK_OFFSET, BLOCK_DIMENSION, BLOCK_DIMENSION)

	love.graphics.setColor(1, 1, 1)
	love.graphics.print("SNEK", gameWidth * 0.5, 0)
	push:finish()
end
