require("globals")

local lg = love.graphics

local snake = {}

--- snake grid
GRID_COLUMNS = 30
GRID_ROWS = 16
GRID_UNIT = math.floor(GAME_WIDTH / GRID_COLUMNS)
GRID_WIDTH, GRID_HEIGHT = GAME_WIDTH, GRID_ROWS * GRID_UNIT
GRID_OFFSET = GRID_UNIT * 0.5
GRID_THICKNESS = math.floor(GRID_UNIT / 8)

BLOCK_UNIT = GRID_UNIT - GRID_THICKNESS
BLOCK_OFFSET = (GRID_THICKNESS - BLOCK_UNIT) * 0.5

local snek = { { 5, 1 }, { 4, 1 }, { 3, 1 }, { 2, 1 }, { 1, 1 } }
local collision = false

---advance snake state
---@param move_x number
---@param move_y number
local function advance_snake(move_x, move_y)
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

local last_move = { 1, 0 }
local next_move = { 1, 0 }
local move = { 1, 0 }
local timer = 0

function snake.update(dt)
	if STATE.paused then
		return
	end
	local x, y = input:get("move")
	if (x ~= 0 and y ~= 0) or (x == 0 and y == 0) or (x == -last_move[1] and y == -last_move[2]) then
		-- do nothing - prevent diagonal movement or 180 deg turn
	else
		next_move = { x, y }
	end
	move = next_move

	if not collision and timer >= 0.3 then
		advance_snake(unpack(move))
		last_move = move
		timer = timer - 0.3
	end

	timer = timer + dt
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
---@param assets table
function snake.draw(theta, assets)
	lg.push()
	draw_grid()
	if not collision then
		lg.setShader(assets.rainbow_shader)
	end
	for i = 1, #snek do
		draw_block(snek[i][1], snek[i][2], collision and 0 or (theta - i / 5))
	end
	lg.setShader()
	lg.pop()
end

return snake
