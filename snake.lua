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
	---@type Grid
	grid = grid.generate(30, 16, GAME.width, GAME.height, 0.1, grid.ALIGN.CENTER, grid.ALIGN.BOTTOM),
	---@type table<string, number>
	intervals = {
		frame = 0.425,
		flash = 0.425 * 0.5,
		hold = 0.425 * 0.3,
		respawn = 3,
	},
	---@type table<string, number>
	timestamps = {
		death = 0,
		frame = 0,
		hold = 0,
		respawn = 0,
	},
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
function snake:advance(move)
	local next = { x = snek[1].x + move.x, y = snek[1].y + move.y }
	for i = #snek, 2, -1 do
		local prev = snek[i - 1]
		-- update body segment locations, back to front
		--snek[i].x, snek[i].y = prev.x, prev.y
		self.tweens:to(snek[i], self.intervals.frame * 0.3, prev):delay(((i - 1) / (#snek * 2)) * self.intervals.frame)
		-- detect collision with self
		if next.x == prev.x and next.y == prev.y then
			tick.delay(self.intervals.flash, function()
				self.state = SNAKE_STATE.COLLISION
			end)
		end
	end
	-- update head location
	self.tweens:to(snek[1], self.intervals.frame * 0.3, {
		x = index_modulo(next.x, self.grid.columns),
		y = index_modulo(next.y, self.grid.rows),
	})
end

local timer = 0

function snake:kill(dt)
	snake.timestamps.death = timer
	self.state = SNAKE_STATE.DEAD
	self.tweens = flux.group()
	local dead_zone = self.grid.rows + 10
	for i = 1, #snek, 1 do
		self.tweens:to(snek[i], 1, { y = dead_zone }):ease("backin"):delay(0.3 + 0.1 * (#snek - i))
	end
end

---@type SnakeMove
local last_input = { x = 1, y = 0 }
---@type SnakeMove
local next_move = last_input
---@type SnakeMove
local last_move = last_input

local function toggle_visibility()
	snake.visible = not snake.visible
end

---respawn snake
---@param dt number
function snake:respawn(dt)
	if timer - self.timestamps.death < self.intervals.respawn then
		return
	end
	self.timestamps.respawn = timer
	self.state = SNAKE_STATE.RESPAWN
	self.tweens = flux.group()
	for i = 1, #snek do
		self.tweens:to(snek[i], self.intervals.frame, snek_default[i]):ease("quadout")
	end
	last_input = { x = 1, y = 0 }
	next_move = last_input
	last_move = last_input
	tick.delay(3 * self.intervals.flash, toggle_visibility)
		:after(self.intervals.flash, toggle_visibility)
		:after(self.intervals.flash, toggle_visibility)
		:after(self.intervals.flash, toggle_visibility)
		:after(self.intervals.flash, toggle_visibility)
		:after(self.intervals.flash, function()
			toggle_visibility()
			self.tweens = flux.group()
			self.state = SNAKE_STATE.ALIVE
			self.timestamps.frame = timer
		end)
end

---interpret input and control snake
---@param dt number
function snake:control(dt)
	local x, y = input:get("move")
	if not x or not y then
		print("invalid input")
	elseif (x ~= 0 and y ~= 0) or (x == 0 and y == 0) or (x == -last_move.x and y == -last_move.y) then
		-- do nothing - prevent diagonal movement or 180 deg turn
		self.timestamps.hold = timer
		next_move = last_input
	elseif x == last_input.x and y == last_input.y then
		-- same direction held
		if timer - self.timestamps.hold >= self.intervals.hold then
			next_move = { x = x * 2, y = y * 2 }
		else
			next_move = last_input
		end
	else
		-- new direction
		self.timestamps.hold = timer
		last_input = { x = x, y = y }
		next_move = last_input
	end

	if timer - self.timestamps.frame >= self.intervals.frame then
		self:advance(next_move)
		last_move = next_move
		self.timestamps.hold = timer
		self.timestamps.frame = timer
	end
end

snake.state_machine = {
	[SNAKE_STATE.ALIVE] = function(dt)
		snake:control(dt)
	end,
	[SNAKE_STATE.COLLISION] = function(dt)
		snake:kill(dt)
	end,
	[SNAKE_STATE.RESPAWN] = function(dt) end,
	[SNAKE_STATE.DEAD] = function(dt)
		snake:respawn(dt)
	end,
}

---update snake
---@param dt number
function snake:update(dt)
	timer = timer + dt
	flux.update(dt)
	tick.update(dt)
	self.tweens:update(dt)

	self.state_machine[self.state](dt)
end

---draw snake
---@param assets table
function snake:draw(assets)
	lg.push()
	grid.draw(self.grid)
	if self.state == SNAKE_STATE.ALIVE then
		lg.setShader(assets.rainbow_shader)
	end
	if self.visible then
		lg.translate(self.grid.offset.x, self.grid.offset.y)
		for i = #snek, 1, -1 do
			assets.rainbow_shader:send("time", GAME.time - i * 0.1)
			grid.draw_cell(self.grid, snek[i].x, snek[i].y)
		end
	end
	lg.setShader()
	lg.pop()
end

return snake
