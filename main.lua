-- Set up the api we are using

package.path = package.path
	.. ";/home/nathan/Documents/code/AutoLuaAPI/?.lua;/home/nathan/Documents/code/noitadata/?.lua"
require("out")
local socket = require("socket")
local frame = math.floor(socket.gettime() * 1000) % 2 ^ 16
function Random(a, b)
	if not a and not b then
		return math.random()
	end
	if not b then
		b = a
		a = 0
	end
	return math.floor(math.random() * (b - a + 1)) + a
end

local _globals = {}

function GlobalsSetValue(key, value)
	_globals[key] = value
end

function GlobalsGetValue(key, value)
	return _globals[key] or value
end

function SetRandomSeed(x, y)
	math.randomseed(x * 591.321 + y * 8541.123 + 124.545)
end

function GameGetFrameNum()
	return frame
end

local print_table = require("print")

function dofile(file)
	return require(file:sub(1, file:len() - 4))
end
dofile_once = dofile

function BeginProjectile(p)
	-- print(p)
end

dofile("data/scripts/gun/gun.lua")
local actions_per_round = 26
local shuffle_deck_when_empty = false
local reload_time = 0
local deck_capacity = 26

local function dbg_cards(pile)
	for _, v in ipairs(pile) do
		print(v.id)
	end
end
local function dbg_wand()
	print("discard")
	dbg_cards(discarded)
	print("hand")
	dbg_cards(hand)
	print("deck")
	dbg_cards(deck)
end

local calls = {}
local cur_node = calls
local counts = {}
local id = 0
for _, v in ipairs(actions) do
	local _a = v.action
	v.action = function(...)
		--print(v.id, "happens")
		local old_node = cur_node
		local new_node = { v.id, {} }
		counts[v.id] = (counts[v.id] or 0) + 1
		cur_node = new_node[2]
		table.insert(old_node, new_node)
		local cur_id = id
		id = id + 1
		--print("pre of ", cur_id)
		--dbg_wand()
		local res = { _a(...) }
		--print("post of ", cur_id)
		--dbg_wand()
		cur_node = old_node
		return unpack(res)
	end
end
ConfigGun_ReadToLua(actions_per_round, shuffle_deck_when_empty, reload_time, deck_capacity)
_set_gun()
local data = require("data")
local arg_list = require("arg_list")
local value = {}
for _, v in ipairs(arg_list) do
	table.insert(value, data[v])
end

ConfigGunActionInfo_ReadToLua(unpack(value))
_set_gun2()

local function easy_add(id, charges, zerod)
	for _, v in ipairs(actions) do
		if v.id == id then
			_add_card_to_deck(
				id,
				0,
				(not v.never_unlimited and -1) or charges or (zerod and 0 or v.max_uses) or -1,
				true
			)
			return
		end
	end
end

if #arg > 0 then
	local p = 1
	local zerod = false
	if arg[p] == "-c" then
		zerod = true
		p = p + 1
	end
	while p <= #arg do
		if tonumber(arg[p + 1]) then
			easy_add(arg[p], tonumber(arg[p + 1]), zerod)
			p = p + 1
		else
			if zerod then
				easy_add(arg[p], 0, true)
			else
				easy_add(arg[p])
			end
		end
		p = p + 1
	end
else
	easy_add("DIVIDE_4")
	easy_add("ADD_TRIGGER")
	easy_add("HOMING")
	easy_add("BLOOD_MAGIC")
end
_start_shot(10000000)
_draw_actions_for_shot(true)
--print_table(calls)

local function make_text(node)
	local build = (node[3] or 1) .. node[1] .. "["
	for _, v in ipairs(node[2]) do
		build = build .. make_text(v)
	end
	return build .. "]"
end

local function flatten(node)
	node[3] = 1
	local i = 1
	local last = ""
	local cur_c = 1
	while i <= #node[2] do
		local v = flatten(node[2][i])
		local cur = make_text(v)
		if last == cur then
			cur_c = cur_c + 1
			table.remove(node[2], i)
		else
			last = cur
			if i ~= 1 then
				node[2][i - 1][3] = cur_c
				cur_c = 1
			end
			i = i + 1
		end
	end
	if i ~= 1 then
		node[2][i - 1][3] = cur_c
		cur_c = 1
	end
	return node
end

--[[print_table(flatten({
	"HAMIS",
	{ { "SPAR BOL", {} }, { "NUKES!", { { "THING", {} } } }, { "NUKES!", { { "THING", {} } } }, { "HAMIS2", {} } },
}))]]

---@class (exact) tree
---@field name string
---@field children tree[]

---@type tree
local t = {
	name = "ROOT",
	children = {
		{
			name = "ROOT2",
			children = {
				{ name = "THING", children = {
					{ name = "THING2", children = {} },
				} },
				{ name = "THING", children = {
					{ name = "THING2", children = {} },
				} },
			},
		},
	},
}

---@param tree tree
---@return table
local function normalise(tree)
	local cur = {}
	cur[1] = tree.name
	cur[2] = {}
	for k, v in ipairs(tree.children) do
		cur[2][k] = normalise(v)
	end
	return cur
end

-- print_table(flatten(normalise(t)))

calls = { "WAND", calls }
do
	-- return
end
--print_table(calls)
flatten(calls)
local out = ""

local function handle(node, prefix, no_extra)
	local t_prefix = ""
	for k = 1, prefix:len() do
		local v = prefix:sub(k, k)
		if v == "#" then
			t_prefix = t_prefix .. (k == prefix:len() and (no_extra and "└" or "├") or "│")
		else
			t_prefix = t_prefix .. " "
		end
	end
	out = out .. t_prefix .. node[1] .. (node[3] ~= 1 and (" (" .. node[3] .. ")") or "") .. "\n"
	for k, v in ipairs(node[2]) do
		local dont = k == #node[2]
		if no_extra then
			prefix = prefix:sub(1, prefix:len() - 1) .. " "
		end
		handle(v, prefix .. "#", dont)
	end
end
handle(calls, "")
if #arg ~= 0 then
	out = "```\n" .. out
end
print(out)
local count_pairs = {}
local big_length = 0
local big_length2 = 0
for k, v in pairs(counts) do
	table.insert(count_pairs, { k, tostring(v), v })
	big_length = math.max(big_length, k:len())
	big_length2 = math.max(big_length2, tostring(v):len())
end
table.sort(count_pairs, function(a, b)
	return a[3] > b[3]
end)
local count_message = "┌" .. ("─"):rep(big_length + 2) .. "┬" .. ("─"):rep(big_length2 + 2) .. "┐\n"
for _, v in ipairs(count_pairs) do
	count_message = count_message
		.. "│ "
		.. v[1]
		.. (" "):rep(big_length - v[1]:len() + 1)
		.. "│ "
		.. v[2]
		.. (" "):rep(big_length2 - v[2]:len() + 1)
		.. "│\n"
end
count_message = count_message
	.. "└"
	.. ("─"):rep(big_length + 2)
	.. "┴"
	.. ("─"):rep(big_length2 + 2)
	.. "┘\n"
print(count_message)
print("```")
