local lume = require("lib.lume")
local flux = require("lib.flux")
local tick = require("lib.tick")

require("globals")
require("util")

local lg = love.graphics

---@enum SNAKE_STATE
local SNAKE_STATE = {
	ALIVE = 1,
	DEAD = 2,
	COLLISION = 3,
	RESPAWN = 4,
}

local snake = {}
snake.tweens = flux.group()

snake.tweens:tick(tick)

---@type SNAKE_STATE
snake.state = SNAKE_STATE.ALIVE

---@type boolean
snake.visible = true

---@type number
snake.frame_interval = 0.425
---@type number
snake.flash_interval = 0.425 * 0.5

---@class Coordinates
---@field x integer
---@field y integer

---@class Cell
---@field unit integer
---@field offset Coordinates

---@class Grid
---@field columns integer
---@field rows integer
---@field width integer
---@field height integer
---@field unit integer
---@field line_width integer
---@field offset Coordinates
---@field cell Cell

---@enum ALIGN
local ALIGN = {
	CENTER = 0.5,
	LEFT = 0,
	RIGHT = 1,
	TOP = 0,
	BOTTOM = 1,
}

---generate grid table with primitives
---@param columns integer
---@param rows integer
---@param max_width integer in pixels
---@param max_height integer in pixels
---@param line_width_pct number percentage of grid as line
---@param horizontal_align? ALIGN
---@param vertical_align? ALIGN
---@return Grid
local function generate_grid(columns, rows, max_width, max_height, line_width_pct, horizontal_align, vertical_align)
	local unit = math.floor(max_width / columns)
	local line_width = math.ceil(unit * line_width_pct)
	local width = unit * columns + line_width
	local height = rows * unit + line_width

	return {
		columns = columns,
		rows = rows,
		width = columns * unit + line_width,
		height = rows * unit + line_width,
		unit = unit,
		line_width = line_width,
		offset = {
			x = (max_width - width) * (horizontal_align or ALIGN.CENTER),
			y = (max_height - height) * (vertical_align or ALIGN.CENTER),
		},
		cell = {
			unit = unit - line_width,
			offset = {
				x = line_width - unit * 0.5,
				y = -unit * 0.5,
			},
		},
	}
end

---@type Grid
snake.grid = generate_grid(30, 16, GAME.width, GAME.height, 0.1, ALIGN.CENTER, ALIGN.BOTTOM)

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
	-- snake.tweens:to(snake.grid, 2, { columns = 80, unit = GAME.width / 80 })
end

---@type SnakeMove
local last_input = { x = 1, y = 0 }
---@type SnakeMove
local next_move = last_input

local function toggle_visibility()
	snake.visible = not snake.visible
end

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
		print("broken")
	elseif (x ~= 0 and y ~= 0) or (x == 0 and y == 0) or (x == -last_input.x and y == -last_input.y) then
		-- do nothing - prevent diagonal movement or 180 deg turn
		next_move = last_input
	elseif x == last_input.x and y == last_input.y then
		if hold_timer >= snake.frame_interval * 0.5 then
			next_move = { x = x * 2, y = y * 2 }
		else
			next_move = last_input
			hold_timer = hold_timer + dt
		end
	else
		last_input = { x = x, y = y }
		next_move = last_input
	end

	if timer >= snake.frame_interval then
		advance_snake(next_move)
		timer = timer - snake.frame_interval
		hold_timer = 0
	end
end

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

---draw grid specified by grid table
---@param grid Grid
---@param color? table
local function draw_grid(grid, color)
	lg.push()
	lg.translate(grid.offset.x, grid.offset.y)
	lg.setBlendMode("alpha")
	lg.setColor(0.2, 0.2, 0.4, 0.5)
	for i = 0, grid.columns do
		lg.rectangle("fill", i * grid.unit, 0, grid.line_width, grid.height)
	end
	for i = 0, grid.rows do
		lg.rectangle("fill", 0, i * grid.unit, grid.width, grid.line_width)
	end
	lg.pop()
end

---draw cell at grid index defined by x, y
---@param grid Grid
---@param x number horizontal index
---@param y number vertical index
local function draw_cell(grid, x, y)
	lg.push()
	lg.setColor(1, 1, 1)
	lg.translate(grid.unit * (x - 0.5), grid.unit * (y - 0.5))
	lg.rectangle("fill", grid.cell.offset.x, grid.cell.offset.y, grid.cell.unit, grid.cell.unit)
	lg.pop()
end

---draw snake
---@param assets table
function snake.draw(assets)
	lg.push()
	draw_grid(snake.grid)
	if snake.state == SNAKE_STATE.ALIVE then
		lg.setShader(assets.rainbow_shader)
	end
	if snake.visible then
		lg.translate(snake.grid.offset.x, snake.grid.offset.y + snake.grid.line_width)
		for i = #snek, 1, -1 do
			assets.rainbow_shader:send("time", GAME.time - i * 0.1)
			draw_cell(snake.grid, snek[i].x, snek[i].y)
		end
	end
	lg.setShader()
	lg.pop()
end

return snake
