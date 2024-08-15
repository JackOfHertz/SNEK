local lg = love.graphics

local grid = {}

---@enum grid.ALIGN
grid.ALIGN = {
	CENTER = 0.5,
	LEFT = 0,
	RIGHT = 1,
	TOP = 0,
	BOTTOM = 1,
}

local math_ceil = math.ceil

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
---@field color table
---@field offset Coordinates
---@field cell Cell

---generate grid table with primitives
---@param columns integer
---@param rows integer
---@param max_width integer in pixels
---@param max_height integer in pixels
---@param line_width_pct number percentage of grid as line
---@param horizontal_align? grid.ALIGN
---@param vertical_align? grid.ALIGN
---@return Grid
function grid.generate(columns, rows, max_width, max_height, line_width_pct, horizontal_align, vertical_align)
	local unit = math.floor(max_width / columns)
	--local unit = 8
	local line_width = math_ceil(unit * line_width_pct)
	local width = unit * columns + line_width
	local height = rows * unit + line_width

	return {
		columns = columns,
		rows = rows,
		width = columns * unit + line_width,
		height = rows * unit + line_width,
		unit = unit,
		line_width = line_width,
		color = { 1, 1, 1, 0.2 },
		offset = {
			x = math_ceil((max_width - width) * (horizontal_align or grid.ALIGN.CENTER)),
			y = math_ceil((max_height - height) * (vertical_align or grid.ALIGN.CENTER)),
		},
		cell = {
			unit = unit - line_width,
			offset = {
				x = line_width - math_ceil(unit * 0.5),
				y = line_width - math_ceil(unit * 0.5),
			},
		},
	}
end

---draw grid specified by grid table
---@param g Grid
function grid.draw(g)
	lg.push()
	lg.translate(g.offset.x, g.offset.y)
	lg.setBlendMode("alpha")
	lg.setColor(g.color)
	for i = 0, g.columns do
		lg.rectangle("fill", i * g.unit, 0, g.line_width, g.height)
	end
	for i = 0, g.rows do
		lg.rectangle("fill", 0, i * g.unit, g.width, g.line_width)
	end
	lg.pop()
end

---draw cell at grid index defined by x, y
---@param g Grid
---@param x number horizontal index
---@param y number vertical index
function grid.draw_cell(g, x, y)
	lg.push()
	lg.setColor(1, 1, 1)
	lg.translate(math_ceil(g.unit * (x - 0.5)), math_ceil(g.unit * (y - 0.5)))
	lg.rectangle("fill", g.cell.offset.x, g.cell.offset.y, g.cell.unit, g.cell.unit)
	lg.pop()
end

function grid.draw_cell_img(g, x, y, img, r, ox, oy)
	lg.push()
	lg.translate(math_ceil(g.unit * (x - 0.5)), math_ceil(g.unit * (y - 0.5)))
	lg.draw(img, ox, oy, r, 1.0, 1.0, -g.cell.offset.x, -g.cell.offset.y)
	lg.pop()
end

return grid
