--- game screen dimensions
GAME_WIDTH, GAME_HEIGHT = 512, 288

--- menu dimensions
MENU_WIDTH, MENU_HEIGHT = GAME_WIDTH * 0.6, GAME_HEIGHT * 0.6
MENU_OFFSET = { (GAME_WIDTH - MENU_WIDTH) * 0.5, (GAME_HEIGHT - MENU_HEIGHT) * 0.5 }
MENU_CENTER = { MENU_WIDTH * 0.5, MENU_HEIGHT * 0.5 }

---@enum MENU_COLORS
MENU_COLORS = {
	background = { 0, 0, 0, 0.3 },
	active = { 1, 1, 1, 1 },
	inactive = { 1, 1, 1, 0.7 },
}

--- snake grid
GRID_COLUMNS = 30
GRID_ROWS = 16
GRID_UNIT = math.floor(GAME_WIDTH / GRID_COLUMNS)
GRID_THICKNESS = math.floor(GRID_UNIT / 8)
GRID_MARGIN = GRID_THICKNESS * 0.5

BLOCK_UNIT = GRID_UNIT - GRID_THICKNESS
BLOCK_OFFSET = BLOCK_UNIT * 0.5

---@enum SCREENS
SCREENS = {
	SNAKE = 1,
}

---@enum MENUS
MENUS = {
	MAIN = 1,
	SETTINGS = 2,
}

---state table
STATE = {
	menus = { MENUS.MAIN },
}