require("globals")
require("util")

local lg = love.graphics

local snake = {}
local tween_group = flux.group()

---@class Cell
---@field unit integer
---@field offset number

---@class Grid
---@field columns integer
---@field rows integer
---@field width integer
---@field height integer
---@field unit integer
---@field line_width integer
---@field cell Cell

---generate grid table with primitives
---@param columns integer
---@param rows integer
---@param max_width integer
---@param line_width_pct number
---@return Grid
local function generate_grid(columns, rows, max_width, line_width_pct)
	local unit = math.floor(max_width / columns)
	local line_width = math.floor(unit * line_width_pct)
	return {
		columns = columns,
		rows = rows,
		width = unit * columns,
		height = rows * unit + line_width,
		unit = unit,
		line_width = line_width,
		cell = {
			unit = unit - line_width,
			offset = line_width - (unit * 0.5),
		},
	}
end
local snake_grid = generate_grid(30, 16, GAME.width, 0.125)

---@class GridCoordinate
---@field x integer
---@field y integer

---@type GridCoordinate[]
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
local collision = false
local delta_time = 0.425

---@class SnakeMove
---@field x number
---@field y number

---advance snake state
---@param grid Grid
---@param move SnakeMove
local function advance_snake(grid, move)
	local next = { x = snek[1].x + move.x, y = snek[1].y + move.y }
	for i = #snek, 2, -1 do
		local prev = snek[i - 1]
		-- update body segment locations, back to front
		--snek[i].x, snek[i].y = prev.x, prev.y
		tween_group:to(snek[i], delta_time * 0.3, prev):delay(((i - 1) / (#snek * 2)) * delta_time)
		-- detect collision with self
		if next.x == prev.x and next.y == prev.y then
			collision = true
			return
		end
	end
	-- update head location
	tween_group:to(snek[1], delta_time * 0.3, {
		x = index_modulo(next.x, grid.columns),
		y = index_modulo(next.y, grid.rows),
	})
end

---@type SnakeMove
local last_input = { x = 1, y = 0 }
---@type SnakeMove
local next_move = last_input

local timer = 0

function snake.update(dt)
	if GAME.state == STATE.PAUSE then
		return
	end
	if collision then
		tween_group = nil
		return
	end
	tween_group:update(dt)
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

	if timer >= delta_time then
		advance_snake(snake_grid, next_move)
		timer = timer - delta_time
	end
	timer = timer + dt
end

---draw grid specified by grid table
---@param grid Grid
local function draw_grid(grid)
	lg.push()
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
---@param theta? number rotation in radians
local function draw_cell(grid, x, y, theta)
	lg.push()
	lg.setColor(1, 1, 1)
	lg.translate(grid.unit * (x - 0.5), grid.unit * (y - 0.5))
	-- lg.rotate(0.2 * math.sin(2 * theta))
	lg.rectangle("fill", grid.cell.offset, grid.cell.offset, grid.cell.unit, grid.cell.unit)
	lg.pop()
end

---draw snake
---@param theta number
---@param assets table
function snake.draw(theta, assets)
	theta = theta or 0
	lg.push()
	lg.translate((GAME.width - snake_grid.width) * 0.5, (GAME.height - snake_grid.height) * 0.5)
	draw_grid(snake_grid)
	if not collision then
		lg.setShader(assets.rainbow_shader)
	end
	for i = 1, #snek do
		assets.rainbow_shader:send("time", GAME.time - i * 0.1)
		draw_cell(snake_grid, snek[i].x, snek[i].y, collision and 0 or (theta - i / 5))
	end
	lg.setShader()
	lg.pop()
end

return snake
