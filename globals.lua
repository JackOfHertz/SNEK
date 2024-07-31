push = require("lib.push")
local baton = require("lib.baton")

--- game screen dimensions
GAME_WIDTH, GAME_HEIGHT = 512, 288

---@enum SCREENS
SCREENS = {
	SNAKE = 1,
}

---state table
STATE = {
	menus = { 1 }, -- main menu
	paused = false,
}

WINDOW_WIDTH, WINDOW_HEIGHT = love.window.getDesktopDimensions()

push:setupScreen(GAME_WIDTH, GAME_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
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
