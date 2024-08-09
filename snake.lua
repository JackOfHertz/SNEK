local lume = require("lib.lume")
local flux = require("lib.flux")
local tick = require("lib.tick")

require("globals")
require("util")
local grid = require("util.grid")

local lg = love.graphics

---@enum SNAKE_STATE
local SNAKE_STATE = {
	ALIVE = 1,
	DEAD = 2,
	COLLISION = 3,
	RESPAWN = 4,
}

local snake = {
	tweens = flux.group(),
	---@type SNAKE_STATE
	state = SNAKE_STATE.ALIVE,
	---@type boolean
	visible = true,
	---@type number
	frame_interval = 0.425,
	---@type number
	flash_interval = 0.425 * 0.5,
	---@type Grid
	grid = grid.generate(30, 16, GAME.width, GAME.height, 0.1, grid.ALIGN.CENTER, grid.ALIGN.BOTTOM),
}

snake.tweens:tick(tick)

---@type Coordinates[]
local snek_default = {
	{ x = 10, y = 1 },
	{ x = 9, y = 1 },
	{ x = 8, y = 1 },
	{ x = 7, y = 1 },
	{ x = 6, y = 1 },
	{ x = 5, y = 1 },
	{ x = 4, y = 1 },
	{ x = 3, y = 1 },
	{ x = 2, y = 1 },
	{ x = 1, y = 1 },
}

local snek = {}

local function move_snek_to_default()
	for i = 1, #snek_default do
		table.insert(snek, lume.merge(snek_default[i]))
	end
end

move_snek_to_default()

---@class SnakeMove
---@field x number
---@field y number

---advance snake state
---@param move SnakeMove
local function advance_snake(move)
	local next = { x = snek[1].x + move.x, y = snek[1].y + move.y }
	local tween_group = snake.tweens
	for i = #snek, 2, -1 do
		local prev = snek[i - 1]
		-- update body segment locations, back to front
		--snek[i].x, snek[i].y = prev.x, prev.y
		tween_group:to(snek[i], snake.frame_interval * 0.3, prev):delay(((i - 1) / (#snek * 2)) * snake.frame_interval)
		-- detect collision with self
		if next.x == prev.x and next.y == prev.y then
			tick.delay(snake.flash_interval, function()
				snake.state = SNAKE_STATE.COLLISION
			end)
		end
	end
	-- update head location
	tween_group:to(snek[1], snake.frame_interval * 0.3, {
		x = index_modulo(next.x, snake.grid.columns),
		y = index_modulo(next.y, snake.grid.rows),
	})
end

local function kill_snake()
	snake.state = SNAKE_STATE.DEAD
	snake.tweens = flux.group()
	local dead_zone = snake.grid.rows + 10
	for i = 1, #snek, 1 do
		snake.tweens:to(snek[i], 1, { y = dead_zone }):ease("backin"):delay(0.3 + 0.1 * (#snek - i))
	end
end

---@type SnakeMove
local last_input = { x = 1, y = 0 }
---@type SnakeMove
local next_move = last_input

local function toggle_visibility()
	snake.visible = not snake.visible
end

---respawn snake
local function respawn_snake()
	snake.state = SNAKE_STATE.RESPAWN
	snake.tweens = flux.group()
	for i = 1, #snek do
		snake.tweens:to(snek[i], snake.frame_interval, snek_default[i]):ease("quadout")
	end
	last_input = { x = 1, y = 0 }
	next_move = last_input
	tick.delay(3 * snake.flash_interval, toggle_visibility)
		:after(snake.flash_interval, toggle_visibility)
		:after(snake.flash_interval, toggle_visibility)
		:after(snake.flash_interval, toggle_visibility)
		:after(snake.flash_interval, toggle_visibility)
		:after(snake.flash_interval, function()
			toggle_visibility()
			snake.tweens = flux.group()
			snake.state = SNAKE_STATE.ALIVE
		end)
end

local timer = 0
local hold_timer = 0

---interpret input and control snake
---@param dt number
local function control_snake(dt)
	local x, y = input:get("move")
	if not x or not y then
		print("invalid input")
	elseif (x ~= 0 and y ~= 0) or (x == 0 and y == 0) or (x == -last_input.x and y == -last_input.y) then
		-- do nothing - prevent diagonal movement or 180 deg turn
		hold_timer = 0
		next_move = last_input
	elseif x == last_input.x and y == last_input.y then
		-- same direction held
		if hold_timer >= snake.frame_interval * 0.25 then
			next_move = { x = x * 2, y = y * 2 }
		else
			next_move = last_input
		end
		hold_timer = hold_timer + dt
	else
		-- new direction
		hold_timer = 0
		last_input = { x = x, y = y }
		next_move = last_input
	end

	if timer >= snake.frame_interval then
		advance_snake(next_move)
		timer = timer - snake.frame_interval
		hold_timer = 0
	end
end

---update snake
---@param dt number
function snake.update(dt)
	flux.update(dt)
	tick.update(dt)
	snake.tweens:update(dt)

	if snake.state == SNAKE_STATE.COLLISION then
		kill_snake()
	elseif snake.state == SNAKE_STATE.RESPAWN then
		return
	elseif snake.state == SNAKE_STATE.DEAD then
		if timer >= 3 then
			respawn_snake()
			timer = timer - 3
		end
	elseif snake.state == SNAKE_STATE.ALIVE then
		control_snake(dt)
	end
	timer = timer + dt
end

---draw snake
---@param assets table
function snake.draw(assets)
	lg.push()
	grid.draw(snake.grid)
	if snake.state == SNAKE_STATE.ALIVE then
		lg.setShader(assets.rainbow_shader)
	end
	if snake.visible then
		lg.translate(snake.grid.offset.x, snake.grid.offset.y)
		for i = #snek, 1, -1 do
			assets.rainbow_shader:send("time", GAME.time - i * 0.1)
			grid.draw_cell(snake.grid, snek[i].x, snek[i].y)
		end
	end
	lg.setShader()
	lg.pop()
end

return snake
