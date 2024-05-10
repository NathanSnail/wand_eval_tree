local vips = require("vips")

local spell_size = 40

---@class point
---@field x integer
---@field y integer

---@class line
---@field colour integer
---@field path point[]

local M = {}

-- Lines that go left come from the bottom
-- All lines start on the right side
-- If all the children are the card 1 to the right the line goes horizontal
-- If not, the connection leaves from (top / bottom) right
-- All incoming connections are centre top / left / bottom
---@param calls numeric_tree
---@param lines line[]?
local function compute_lines(calls, lines)
	lines = lines or {}
end

---@class (exact) numeric_tree
---@field index integer
---@field children numeric_tree[]

---@param calls node
---@return numeric_tree
local function make_numeric(calls)
	---@type numeric_tree
	local new = { index = calls.index or -1, children = {} }
	for _, v in ipairs(calls.children) do
		table.insert(new.children, make_numeric(v))
	end
	return new
end

---@param base any
---@param lines line[]
local function draw(base, lines) end

---@param calls node
local function render_spells(calls) end

function M.render(calls)
	local numeric = make_numeric(calls)
	local lines = compute_lines(numeric)
end

return M
