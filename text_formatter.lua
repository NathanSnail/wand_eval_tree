---@class text_formatter
local M = {}

local colour_char = string.char(27)
M.colour_codes =
	{ RESET = "0", GREY = "30", RED = "31", GREEN = "32", YELLOW = "33", BLUE = "34", PINK = "35", CYAN = "36" }
for k, v in pairs(M.colour_codes) do
	M.colour_codes[k] = colour_char .. "[" .. v .. "m"
end

M.ty_map = {}
local col_map = {
	[ACTION_TYPE_PROJECTILE] = M.colour_codes.RED,
	[ACTION_TYPE_STATIC_PROJECTILE] = M.colour_codes.RED,
	[ACTION_TYPE_MODIFIER] = M.colour_codes.BLUE,
	[ACTION_TYPE_UTILITY] = M.colour_codes.PINK,
	[ACTION_TYPE_MATERIAL] = M.colour_codes.GREEN,
	[ACTION_TYPE_OTHER] = M.colour_codes.YELLOW,
	[ACTION_TYPE_DRAW_MANY] = M.colour_codes.CYAN,
}
local colours = true

local function colour_of(id)
	return col_map[M.ty_map[id] or ACTION_TYPE_DRAW_MANY]
end

function M.id_text(id)
	if not colours then
		return id
	end
	return colour_of(id) .. id
end

---@param a node
---@param b node
---@return boolean?
function M.colour_compare(a, b)
	if colour_of(a.name) ~= colour_of(b.name) then
		return colour_of(a.name) > colour_of(b.name)
	end
	return nil
end

function M.set_colours(cols)
	colours = cols
	if not cols then
		for k, v in pairs(M.colour_codes) do
			M.colour_codes[k] = ""
		end
	end
end

return M
