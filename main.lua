require("globals")
local ui = require("ui")
local snake = require("snake")

local lg = love.graphics
local assets = {}

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
		{ name = "snake_canvas" },
		{ name = "ui_canvas" },
	})
end

local theta = 0
local time = 0

function love.update(dt)
	input:update()
	flux.update(dt)

	theta = theta + 0.5 * math.pi * dt
	time = time + dt

	-- update time-based shaders
	assets.water_shader:send("time", time)
	assets.rainbow_shader:send("time", time)

	snake.update(dt)
	ui.update()
end

function love.draw()
	push:start()
	push:setCanvas("base_canvas")
	lg.setColor(0.05, 0.05, 0.05)
	lg.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

	push:setCanvas("snake_canvas")
	snake.draw(theta, assets)

	push:setCanvas("ui_canvas")
	ui.draw(theta, assets)

	push:finish()
end
