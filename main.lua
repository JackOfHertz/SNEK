require("lib.lovedebug")

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

	assets.title_font = lg.newFont("assets/fonts/joystix_monospace.otf", 16)
	assets.option_font = lg.newFont("assets/fonts/joystix_monospace.otf", 10)

	assets.simplex = lg.newImage("shaders/simplex-noise-64.png")
	assets.water_shader = lg.newShader("shaders/water.glsl")
	assets.water_shader:send("simplex", assets.simplex)
	assets.water_shader:send("amp", 0.03)

	assets.rainbow_shader = lg.newShader("shaders/rainbow.glsl")

	push:setupCanvas({
		{ name = "base_canvas" },
		{ name = "game_canvas" },
		{ name = "ui_canvas" },
	})
	snake:load()
end

function love.update(dt)
	input:update()

	GAME.time = GAME.time + dt

	assets.water_shader:send("time", GAME.time)

	ui.update()
	if GAME.state == STATE.PAUSE then
		return
	end
	snake:update(dt, assets)
end

function love.draw()
	push:start()
	push:setCanvas("base_canvas")
	lg.setColor(0.05, 0.05, 0.05)
	lg.rectangle("fill", 0, 0, GAME.width, GAME.height)

	push:setCanvas("game_canvas")
	snake:draw(assets)

	push:setCanvas("ui_canvas")
	ui.draw(assets)

	push:finish()
end
