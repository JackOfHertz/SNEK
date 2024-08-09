---correct modulus operation for 1-indexed table lookups
---@param a number
---@param b number
---@return number
function index_modulo(a, b)
	return ((a - 1) % b) + 1
end

---@class Coordinates
---@field x integer
---@field y integer
