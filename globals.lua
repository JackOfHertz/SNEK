push = require("lib.push")
local baton = require("lib.baton")

---@enum SCREENS
SCREENS = {
	SNAKE = 1,
}

---Game state enumerator
---@enum STATE
STATE = {
	MENU = 1,
	PLAY = 2,
	PAUSE = 3,
	EXIT = 4,
}

---Game state
---@class GameState
---@field width integer Game screen width in logical pixels
---@field height integer Game screen height in logical pixels
---@field menus number[] menu_index array
---@field time number Counter - seconds since game start
---@field state STATE
GAME = {
	width = 320,
	height = 180,
	menus = { 1 },
	time = 0,
	state = STATE.MENU,
}

---@type integer, integer
WINDOW_WIDTH, WINDOW_HEIGHT = love.window.getDesktopDimensions()

push:setupScreen(GAME.width, GAME.height, WINDOW_WIDTH, WINDOW_HEIGHT, {
	canvas = true,
	fullscreen = false,
	highdpi = true,
	pixelperfect = true,
	resizable = true,
})

input = baton.new({
	controls = {
		left = { "key:left", "key:a", "axis:leftx-", "button:dpleft" },
		right = { "key:right", "key:d", "axis:leftx+", "button:dpright" },
		up = { "key:up", "key:w", "axis:lefty-", "button:dpup" },
		down = { "key:down", "key:s", "axis:lefty+", "button:dpdown" },
		action = { "key:x", "button:a" },
		back = { "key:escape", "button:back" },
		confirm = { "key:return", "key:space", "key:x", "button:a" },
	},
	pairs = {
		move = { "left", "right", "up", "down" },
	},
	joystick = love.joystick.getJoysticks()[1],
})
