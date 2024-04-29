-- Set up the api we are using

---@class (exact) engine_data

---@class fake_engine
---@field text_formatter text_formatter
local M = {}
package.path = package.path
	.. ";/home/nathan/Documents/code/AutoLuaAPI/?.lua;/home/nathan/Documents/code/noitadata/?.lua"
local _print = print
require("out")
print = _print
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

local calls
local cur_node
local cur_parent
local nodes_to_shot_ref
local shot_refs_to_nums
local lines_to_shot_nums
local cur_shot_num
local counts

_create_shot = create_shot
function create_shot(...)
	local uv = { _create_shot(...) }
	local v = uv[1]
	nodes_to_shot_ref[cur_parent] = v
	shot_refs_to_nums[v] = cur_shot_num
	cur_shot_num = cur_shot_num + 1
	return unpack(uv)
end

for _, v in ipairs(actions) do
	M.text_formatter.ty_map[v.id] = v.type
	local _a = v.action
	v.action = function(...)
		--print(v.id, "happens")
		local old_node = cur_node
		local new_node = { v.id, {} }
		counts[v.id] = (counts[v.id] or 0) + 1
		cur_node = new_node[2]
		cur_parent = new_node
		table.insert(old_node, new_node)
		local res = { _a(...) }
		M.cur_node = old_node
		return unpack(res)
	end
end

function M.evaluate(actions_per_round, shuffle_deck_when_empty, reload_time, deck_capacity, mana)
	calls = { "WAND", {} }
	cur_node = calls[2]
	cur_parent = calls
	nodes_to_shot_ref = {}
	shot_refs_to_nums = {}
	lines_to_shot_nums = {}
	cur_shot_num = 1
	counts = {}

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

	_start_shot(mana)
	_draw_actions_for_shot(true)
end

function M.easy_add(id, charges, zerod)
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

return M
