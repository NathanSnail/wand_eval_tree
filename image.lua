local vips = require("vips")

local spell_size = 40

---@class point
---@field x integer
---@field y integer

---@class line
---@field colour integer
---@field path point[]

---@alias graph integer[][]
local M = {}

-- Lines that go left come from the bottom
-- All lines start on the right side
-- If all the children are the card 1 to the right the line goes horizontal
-- If not, the connection leaves from (top / bottom) right
-- All incoming connections are centre top / left / bottom
---@param edges graph
---@return line[]
local function compute_lines(edges)
	---@type line[]
	local lines = {}
	local height_map = {}
	for i = 1, #edges do
		height_map[i] = 0
	end
	-- forward pass
	for gap = 1, #edges do
		for start = 1, #edges - gap do
			for _, v in ipairs(edges[start]) do
				if v == gap + start then
					local highest = 0
					for i = start + 1, gap + start - 1 do
						highest = math.max(highest, height_map[i])
					end
					for i = start + 1, gap + start - 1 do
						height_map[i] = highest + 1
					end

					local s = { x = start + 0.5, y = 1 }
					local u = { x = start + 0.5, y = highest + 1 }
					local r = { x = start + gap, y = highest + 1 }
					local d = { x = start + gap, y = 1 }

					table.insert(lines, { s, u, r, d })
					break
				end
			end
		end
	end
end

---@param calls numeric_tree
---@param graph graph?
---@return graph
local function compute_graph(calls, graph)
	graph = graph or {}
	local function add_edge(start, finish)
		graph[start] = graph[start] or {}
		table.insert(graph[start], finish)
	end
	local cur = calls.index
	for _, v in ipairs(calls.children) do
		add_edge(cur, v.index)
		compute_graph(v, graph)
	end
	return graph
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
