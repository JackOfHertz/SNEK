require("globals")
require("util")

local lg = love.graphics

---@enum SNAKE_STATE
local SNAKE_STATE = {
	ALIVE = 1,
	DEAD = 2,
	COLLISION = 3,
}

local snake = {}
snake.tweens = flux.group()

---@type SNAKE_STATE
snake.state = SNAKE_STATE.ALIVE

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

---generate grid table with primitives
---@param columns integer
---@param rows integer
---@param max_width integer in pixels
---@param max_height integer in pixels
---@param line_width_pct number percentage of grid as line
---@return Grid
local function generate_grid(columns, rows, max_width, max_height, line_width_pct)
	local unit = math.floor(max_width / columns)
	local width = unit * columns
	local line_width = math.ceil(unit * line_width_pct)
	local height = rows * unit + line_width
	return {
		columns = columns,
		rows = rows,
		width = unit * columns,
		height = rows * unit + line_width,
		unit = unit,
		line_width = line_width,
		offset = {
			x = (max_width - width) * 0.5,
			y = (max_height - height) * 0.5,
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
snake.grid = generate_grid(30, 16, GAME.width, GAME.height, 0.1)

---@type Coordinates[]
local snek = {
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
snake.frame_interval = 0.425

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
			snake.state = SNAKE_STATE.COLLISION
			return
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
	local dead_zone = snake.grid.rows + 1
	for i = #snek, 1, -1 do
		snake.tweens:to(snek[i], 1, { y = dead_zone }):ease("backin"):delay(0.3 + 0.1 * (#snek - i))
	end
end

local function respawn_snake() end

---@type SnakeMove
local last_input = { x = 1, y = 0 }
---@type SnakeMove
local next_move = last_input

local timer = 0

function snake.update(dt)
	snake.tweens:update(dt)
	if snake.state == SNAKE_STATE.COLLISION then
		kill_snake()
		return
	elseif snake.state == SNAKE_STATE.DEAD then
		return
	end

	local x, y = input:get("move")
	if not x or not y then
		print("broken")
	elseif (x ~= 0 and y ~= 0) or (x == 0 and y == 0) or (x == -last_input.x and y == -last_input.y) then
		-- do nothing - prevent diagonal movement or 180 deg turn
		next_move = last_input
	elseif x == last_input.x and y == last_input.y then
		last_input = { x = x, y = y }
		next_move = { x = x * 2, y = y * 2 }
	else
		last_input = { x = x, y = y }
		next_move = last_input
	end

	if timer >= snake.frame_interval then
		advance_snake(next_move)
		timer = timer - snake.frame_interval
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
	lg.translate(grid.unit * (x + 0.5), grid.unit * (y + 0.5))
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
	for i = 1, #snek do
		assets.rainbow_shader:send("time", GAME.time - i * 0.1)
		draw_cell(snake.grid, snek[i].x, snek[i].y)
	end
	lg.setShader()
	lg.pop()
end

return snake
