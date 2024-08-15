local lume = require("lib.lume")
local flux = require("lib.flux")
local tick = require("lib.tick")

require("globals")
local util = require("util")
local grid = require("util.grid")

local lg = love.graphics

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

---@enum SNAKE_STATE
local SNAKE_STATE = {
	ALIVE = 1,
	DEAD = 2,
	COLLISION = 3,
	RESPAWN = 4,
}

---@class SnakeMove
---@field x number
---@field y number

local snake = {
	tweens = flux.group(),
	---@type SNAKE_STATE
	state = SNAKE_STATE.ALIVE,
	---@type boolean
	visible = true,
	---@type Grid
	--grid = grid.generate(30, 16, GAME.width, GAME.height, 0.1, grid.ALIGN.CENTER, grid.ALIGN.BOTTOM),
	grid = grid.generate(35, 20, GAME.width, GAME.height, 0.1, grid.ALIGN.CENTER, grid.ALIGN.BOTTOM),
	---@type table<string, number>
	interval = {
		frame = 0.425,
		collision = 0.425 * 0.5,
		flash = 0.425 * 0.5,
		hold = 0.425 * 0.3,
		respawn = 3,
	},
	---@type table<string, number>
	timestamp = {
		death = 0,
		frame = 0,
		hold = 0,
		respawn = 0,
	},
	---@type table<"next"|"last", SnakeMove>
	move = {
		next = { x = 1, y = 0 },
		last = { x = 1, y = 0 },
	},
	---@type table<"last", SnakeMove>
	input = {
		last = { x = 1, y = 0 },
	},
	---@type Coordinates[]
	body = lume.map(snek_default, lume.clone),
}

-- connect flux and tick instances
snake.tweens:tick(tick)

---advance snake state
---@private
function snake:advance()
	local body = self.body
	local next = { x = body[1].x + self.move.next.x, y = body[1].y + self.move.next.y }
	local duration_pct = 0.0
	local delay_pct = 0.0
	for i = #body, 2, -1 do
		local prev = body[i - 1]
		-- update body segment locations, back to front
		--snek[i].x, snek[i].y = prev.x, prev.y
		if math.abs(prev.x - body[i].x) > 1 or math.abs(prev.y - body[i].y) > 1 then
			duration_pct = 0.9
			delay_pct = (i - 1) / (#body * 5)
		else
			duration_pct = 0.3
			delay_pct = (i - 1) / (#body * 2)
		end
		self.tweens:to(body[i], duration_pct * self.interval.frame, prev):delay(delay_pct * self.interval.frame)
		-- detect collision with self
		if next.x == prev.x and next.y == prev.y then
			tick.delay(self.interval.collision, function()
				self.state = SNAKE_STATE.COLLISION
			end)
		end
	end
	-- update head location
	if math.abs(self.move.next.x) > 1 or math.abs(self.move.next.y) > 1 then
		duration_pct = 0.9
	else
		duration_pct = 0.3
	end
	self.tweens:to(body[1], duration_pct * self.interval.frame, {
		x = util.i_modulo(next.x, self.grid.columns),
		y = util.i_modulo(next.y, self.grid.rows),
	})
end

local timer = 0

---@private
function snake:kill(dt)
	self.timestamp.death = timer
	self.state = SNAKE_STATE.DEAD
	self.tweens = flux.group()
	local dead_zone = self.grid.rows + 10
	for i = 1, #self.body, 1 do
		self.tweens:to(self.body[i], 1, { y = dead_zone }):ease("backin"):delay(0.3 + 0.1 * (#self.body - i))
	end
end

local function toggle_visibility()
	snake.visible = not snake.visible
end

---respawn snake
---@private
---@param dt number
function snake:respawn(dt)
	if timer - self.timestamp.death < self.interval.respawn then
		return
	end
	self.timestamp.respawn = timer
	self.state = SNAKE_STATE.RESPAWN
	self.tweens = flux.group()
	for i = 1, #self.body do
		self.tweens:to(self.body[i], self.interval.frame, snek_default[i]):ease("quadout")
	end
	self.input.last = { x = 1, y = 0 }
	self.move.next = self.input.last
	self.move.last = self.input.last
	tick.delay(3 * self.interval.flash, toggle_visibility)
		:after(self.interval.flash, toggle_visibility)
		:after(self.interval.flash, toggle_visibility)
		:after(self.interval.flash, toggle_visibility)
		:after(self.interval.flash, toggle_visibility)
		:after(self.interval.flash, function()
			toggle_visibility()
			self.tweens = flux.group()
			self.state = SNAKE_STATE.ALIVE
			self.timestamp.frame = timer
		end)
end

---interpret input and control snake
---@param dt number
function snake:control(dt)
	local x, y = input:get("move")
	if not x or not y then
		print("invalid input")
	elseif (x ~= 0 and y ~= 0) or (x == 0 and y == 0) or (x == -self.move.last.x and y == -self.move.last.y) then
		-- do nothing - prevent diagonal movement or 180 deg turn
		self.timestamp.hold = timer
		self.move.next = self.input.last
	elseif x == self.input.last.x and y == self.input.last.y then
		-- same direction held
		if timer - self.timestamp.hold >= self.interval.hold then
			-- move two blocks when input held
			self.move.next = { x = x * 2, y = y * 2 }
		else
			self.move.next = self.input.last
		end
	else
		-- new direction
		self.timestamp.hold = timer
		self.input.last = { x = x, y = y }
		self.move.next = self.input.last
	end

	if timer - self.timestamp.frame >= self.interval.frame then
		self:advance()
		self.move.last = self.move.next
		self.timestamp.hold = timer
		self.timestamp.frame = timer
	end
end

snake.state_machine = {
	[SNAKE_STATE.ALIVE] = function(self, dt, assets)
		self.shader = assets.rainbow_shader
		self.shader_amplitude = 1
		self:control(dt)
	end,
	[SNAKE_STATE.COLLISION] = function(self, dt, assets)
		self.shader = assets.water_shader
		self.shader_amplitude = 0.2
		self:kill(dt)
	end,
	[SNAKE_STATE.RESPAWN] = function(self, dt, assets)
		self.shader = assets.water_shader
		self.shader_amplitude = 0.4
	end,
	[SNAKE_STATE.DEAD] = function(self, dt, assets)
		self.shader = assets.water_shader
		self:respawn(dt)
	end,
}

function snake:load()
	snake.head_img = lg.newImage("assets/img/snake_head.png")
	snake.body_img = lg.newImage("assets/img/snake_body.png")
end

---update snake
---@param dt number
---@param assets any
function snake:update(dt, assets)
	timer = timer + dt
	flux.update(dt)
	tick.update(dt)
	self.tweens:update(dt)

	self.state_machine[self.state](self, dt, assets)
end

---draw snake
---@param assets table
function snake:draw(assets)
	grid.draw(self.grid)
	if not self.visible then
		return
	end
	lg.push()
	lg.setShader(self.shader)
	lg.translate(self.grid.offset.x, self.grid.offset.y)
	lg.setColor(1, 1, 1, 1)
	self.shader:send("amp", self.shader_amplitude)
	for i = #self.body, 2, -1 do
		self.shader:send("time", GAME.time - i * 0.1)
		local diff = {
			x = self.body[i - 1].x - self.body[math.min(i + 1, #self.body)].x,
			y = self.body[i - 1].y - self.body[math.min(i + 1, #self.body)].y,
		}
		grid.draw_cell_img(
			self.grid,
			self.body[i].x,
			self.body[i].y,
			self.body_img,
			math.atan2(diff.y, diff.x),
			math.abs(diff.x) >= 1.9 and 0 or self.body[i].y ~= self.body[i - 1].y and -diff.x or diff.x,
			math.abs(diff.y) >= 1.9 and 0 or self.body[i].x ~= self.body[i - 1].x and -diff.y or diff.y
		)
	end
	self.shader:send("time", GAME.time - 0.1)
	grid.draw_cell_img(
		self.grid,
		self.body[1].x,
		self.body[1].y,
		self.head_img,
		math.atan2(self.move.next.y, self.move.next.x),
		0,
		0
	)
	lg.setShader()
	lg.pop()
end

return snake
