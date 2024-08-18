local lume = require("lib.lume")
local flux = require("lib.flux")
local tick = require("lib.tick")

require("globals")
local util = require("util")
local grid = require("util.grid")

local lg = love.graphics

local timer = 0

local function noop() end

---@class SnakeMove
---@field x number
---@field y number

---@class SerializableSnake
---@field state State
---@field visible boolean
---@field grid Grid
---@field interval table<string, number>
---@field timestamp table<string, number>
---@field move table<"next"|"last", SnakeMove>
---@field input table<"last", SnakeMove>
---@field body Coordinates[]

---@class Snake : SerializableSnake
---@field head_img any
---@field body_img any
---@field update_fn fun(self: any, dt: number): nil
---@field tweens any
---@field depth_tweens any
---@field state_machine table<State, table<string, any>>
---@field shader love.Shader
---@field shader_amplitude number
local snake = {}

---@enum State
local State = {
	ALIVE = 1,
	COLLISION = 2,
	DEAD = 3,
	RESPAWN = 4,
	RESPAWNING = 5,
}

---template state
---@return SerializableSnake
local function snake_default()
	---frame time
	local ft = 0.425
	return {
		state = State.ALIVE,
		visible = false,
		grid = grid.generate(35, 20, GAME.width, GAME.height, 0.1, grid.ALIGN.CENTER, grid.ALIGN.BOTTOM),
		interval = {
			frame = ft,
			collision = ft * 0.5,
			flash = ft * 0.5,
			hold = ft * 0.2,
			respawn = 3,
		},
		timestamp = {
			death = timer,
			frame = timer,
			hold = timer,
			respawn = timer,
		},
		move = {
			next = { x = 1, y = 0 },
			last = { x = 1, y = 0 },
		},
		input = {
			last = { x = 1, y = 0 },
		},
		body = {
			{ x = 10, y = 1, z = 1.0 },
			{ x = 9, y = 1, z = 1.0 },
			{ x = 8, y = 1, z = 1.0 },
			{ x = 7, y = 1, z = 1.0 },
			{ x = 6, y = 1, z = 1.0 },
			{ x = 5, y = 1, z = 1.0 },
			{ x = 4, y = 1, z = 1.0 },
			{ x = 3, y = 1, z = 1.0 },
			{ x = 2, y = 1, z = 1.0 },
			{ x = 1, y = 1, z = 1.0 },
		},
	}
end

---@param obj Snake
---@param assets any
---@return table<string, any>
local function state_machine(obj, assets)
	return {
		[State.ALIVE] = {
			shader = assets.rainbow_shader,
			shader_amplitude = 1,
			update_fn = obj.alive,
			visible = true,
		},
		[State.COLLISION] = {
			shader = assets.water_shader,
			shader_amplitude = 0.2,
			update_fn = obj.collision,
		},
		[State.DEAD] = {
			shader = assets.water_shader,
			update_fn = obj.dead,
		},
		[State.RESPAWN] = {
			shader = assets.water_shader,
			shader_amplitude = 0.4,
			update_fn = obj.respawn,
		},
		[State.RESPAWNING] = {
			update_fn = noop,
		},
	}
end

---change state via state machine
---@param state State
function snake:set_state(state)
	lume.extend(self, self.state_machine[state])
	self.state = state
end

---first time load
---@param assets any
function snake:load(assets)
	lume.extend(self, snake_default(), {
		--- reference state
		state_machine = state_machine(self, assets),
		head_img = lg.newImage("assets/img/snake_head.png"),
		body_img = lg.newImage("assets/img/snake_body.png"),
		tweens = flux.group(),
		depth_tweens = flux.group(),
	})
	-- connect flux and tick instances
	self.tweens:tick(tick)
	self.depth_tweens:tick(tick)

	self:set_state(State.ALIVE)
end

---advance snake state
function snake:advance()
	local body = self.body
	local next = { x = body[1].x + self.move.next.x, y = body[1].y + self.move.next.y }
	local duration_pct, delay_pct
	for i = #body, 2, -1 do
		local prev = body[i - 1]
		-- update body segment locations, back to front
		--snek[i].x, snek[i].y = prev.x, prev.y
		if math.abs(prev.x - body[i].x) > 1.1 or math.abs(prev.y - body[i].y) > 1.1 then
			duration_pct = 0.9
			delay_pct = (i - 1) / (#body * 5)
			local duration = duration_pct * self.interval.frame
			local delay = delay_pct * self.interval.frame
			self.depth_tweens
				:to(body[i], 0.5 * duration, { z = 1.75 })
				:delay(delay)
				:after(body[i], 0.5 * duration, { z = 1.0 })
		else
			duration_pct = 0.3
			delay_pct = (i - 1) / (#body * 2)
		end
		self.tweens:to(body[i], duration_pct * self.interval.frame, prev):delay(delay_pct * self.interval.frame)
		-- detect collision with self
		if next.x == prev.x and next.y == prev.y then
			tick.delay(self.interval.collision, function()
				self:set_state(State.COLLISION)
			end)
		end
	end
	-- update head location
	if math.abs(self.move.next.x) > 1 or math.abs(self.move.next.y) > 1 then
		duration_pct = 0.9
		local duration = duration_pct * self.interval.frame
		self.depth_tweens:to(body[1], 0.5 * duration, { z = 1.75 }):after(body[1], 0.5 * duration, { z = 1 })
	else
		duration_pct = 0.3
	end
	self.tweens:to(body[1], duration_pct * self.interval.frame, {
		x = util.i_modulo(next.x, self.grid.columns),
		y = util.i_modulo(next.y, self.grid.rows),
	})
end

---interpret input and control snake
---@param dt number
function snake:alive(dt)
	local x, y = input:get("move")
	local dash = input:get("dash")

	-- interpret input
	if not x or not y then
		print("nil input value:", "x=", x, "y=", y)
	elseif (x ~= 0 and y ~= 0) or (x == 0 and y == 0) or (x == -self.move.last.x and y == -self.move.last.y) then
		-- do nothing - prevent diagonal movement or 180 deg turn
		self.timestamp.hold = timer
		self.move.next = self.input.last
	elseif x == self.input.last.x and y == self.input.last.y then
		-- same direction held
		if timer - self.timestamp.hold >= self.interval.hold then
			-- move two blocks
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

function snake:collision(dt)
	self:set_state(State.DEAD)
	self.timestamp.death = timer
	self.tweens = flux.group()
	local dead_zone = self.grid.rows + 10
	for i = 1, #self.body, 1 do
		self.tweens:to(self.body[i], 1, { y = dead_zone }):ease("backin"):delay(0.3 + 0.1 * (#self.body - i))
	end
end

function snake:dead(dt)
	if timer - self.timestamp.death >= self.interval.respawn then
		self:set_state(State.RESPAWN)
	end
end

local function toggle_visibility()
	snake.visible = not snake.visible
end

---respawn snake
---@param dt number
function snake:respawn(dt)
	self:set_state(State.RESPAWNING)
	self.timestamp.respawn = timer
	self.tweens = flux.group()
	local d = snake_default()
	for i = 1, #d.body do
		self.tweens:to(self.body[i], self.interval.frame, d.body[i]):ease("quadout")
	end
	self.input = d.input
	self.move = d.move
	tick.delay(3 * self.interval.flash, toggle_visibility)
		:after(self.interval.flash, toggle_visibility)
		:after(self.interval.flash, toggle_visibility)
		:after(self.interval.flash, toggle_visibility)
		:after(self.interval.flash, toggle_visibility)
		:after(self.interval.flash, function()
			toggle_visibility()
			self.tweens = flux.group()
			self:set_state(State.ALIVE)
			self.timestamp.frame = timer
		end)
end

---update snake
---@param dt number
function snake:update(dt)
	timer = timer + dt
	flux.update(dt)
	tick.update(dt)
	self.tweens:update(dt)
	self.depth_tweens:update(dt)
	self.update_fn(self, dt)
end

---draw snake
function snake:draw()
	grid.draw(self.grid)
	if not self.visible then
		return
	end
	lg.push()
	lg.setShader(self.shader)
	lg.translate(self.grid.offset.x, self.grid.offset.y)
	lg.setColor(1, 1, 1, 1)
	self.shader:send("amp", self.shader_amplitude)
	-- snake body loop
	local g, b = self.grid, self.body
	local diff = {}
	local tail = true
	for i = #b, 2, -1 do
		self.shader:send("time", GAME.time - i * 0.1)
		local curr, prev = b[i], b[i - 1]
		if i == #b then
			diff = {
				x = prev.x - curr.x,
				y = prev.y - curr.y,
			}
			tail = true
		else
			diff = {
				x = prev.x - b[i + 1].x,
				y = prev.y - b[i + 1].y,
			}
			tail = false
		end
		lg.push()
		lg.translate(math.ceil(g.unit * (curr.x - 0.5)), math.ceil(g.unit * (curr.y - 0.5)))
		lg.draw(
			self.body_img,
			(tail or math.abs(diff.x) >= 1.9) and 0 or curr.y ~= prev.y and math.max(-2, -diff.x) or math.min(2, diff.x),
			(tail or math.abs(diff.y) >= 1.9) and 0 or curr.x ~= prev.x and math.max(-2, -diff.y) or math.min(2, diff.y),
			math.atan2(diff.y, diff.x),
			curr.z,
			curr.z,
			-g.cell.offset.x,
			-g.cell.offset.y
		)
		lg.pop()
	end
	-- snake head
	self.shader:send("time", GAME.time - 0.1)
	lg.translate(math.ceil(g.unit * (b[1].x - 0.5)), math.ceil(g.unit * (b[1].y - 0.5)))
	lg.draw(
		self.head_img,
		0,
		0,
		math.atan2((self.move.next.y + self.move.last.y) * 0.5, (self.move.next.x + self.move.last.x) * 0.5),
		b[1].z,
		b[1].z,
		-g.cell.offset.x,
		-g.cell.offset.y
	)
	lg.setShader()
	lg.pop()
end

return snake
