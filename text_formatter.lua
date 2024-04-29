---@class text_formatter
local M = {}

local colour_char = string.char(27)
M.colour_codes =
	{ RESET = "0", GREY = "30", RED = "31", GREEN = "32", YELLOW = "33", BLUE = "34", PINK = "35", CYAN = "36" }
for k, v in pairs(M.colour_codes) do
	M.colour_codes[k] = colour_char .. "[" .. v .. "m"
end

M.ty_map = { WAND = ACTION_TYPE_DRAW_MANY }
local col_map = {
	[ACTION_TYPE_PROJECTILE] = M.colour_codes.RED,
	[ACTION_TYPE_STATIC_PROJECTILE] = M.colour_codes.RED,
	[ACTION_TYPE_MODIFIER] = M.colour_codes.BLUE,
	[ACTION_TYPE_UTILITY] = M.colour_codes.PINK,
	[ACTION_TYPE_MATERIAL] = M.colour_codes.GREEN,
	[ACTION_TYPE_OTHER] = M.colour_codes.YELLOW,
	[ACTION_TYPE_DRAW_MANY] = M.colour_codes.CYAN,
}
M.colours = false

function M.id_text(id)
	if not M.colours then
		return id
	end
	return string.char(27) .. "[" .. col_map[M.ty_map[id]] .. "m" .. id .. string.char(27) .. "[30m"
end

function M.colour_compare(a, b, engine_data)
	if col_map[engine_data.ty_map[a[1]]] ~= col_map[engine_data.ty_map[b[1]]] then
		return col_map[engine_data.ty_map[a[1]]] > col_map[engine_data.ty_map[b[1]]]
	end
	return nil
end

return M
