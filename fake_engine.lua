-- Set up the api we are using

---@class (exact) shot_ref
---@field state {string: any}

---@class fake_engine
local M = {}
package.path = package.path .. ";/home/nathan/Documents/code/noitadata/?.lua"
require("data/scripts/gun/gun_enums")
---@param text_formatter text_formatter
function M.initialise_engine(text_formatter)
	local _print = print
	require("AutoLuaAPI.out")
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

	_create_shot = create_shot
	function create_shot(...)
		local uv = { _create_shot(...) }
		local v = uv[1]
		M.nodes_to_shot_ref[M.cur_parent] = v
		M.shot_refs_to_nums[v] = M.cur_shot_num
		M.cur_shot_num = M.cur_shot_num + 1
		return unpack(uv)
	end

	for _, v in ipairs(actions) do
		text_formatter.ty_map[v.id] = v.type
		local _a = v.action
		v.action = function(...)
			--print(v.id, "happens")
			local old_node = M.cur_node
			local new_node = { name = v.id, children = {} }
			M.counts[v.id] = (M.counts[v.id] or 0) + 1
			M.cur_node = new_node.children
			M.cur_parent = new_node
			table.insert(old_node, new_node)
			local res = { _a(...) }
			M.cur_node = old_node
			return unpack(res)
		end
	end
end

---@param options formatter_options
function M.evaluate(options)
	M.calls = { name = "Wand", children = {} }
	M.nodes_to_shot_ref = {}
	M.shot_refs_to_nums = {}
	M.lines_to_shot_nums = {}
	M.cur_shot_num = 1
	M.counts = {}

	ConfigGun_ReadToLua(options.spells_per_cast, false, options.reload_time, 66)
	_set_gun()
	local data = require("data")
	local arg_list = require("arg_list")
	data.fire_rate_wait = options.cast_delay
	local value = {}
	for _, v in ipairs(arg_list) do
		table.insert(value, data[v])
	end

	mana = options.mana
	for i = 1, options.number_of_casts do
		table.insert(M.calls.children, { name = "Cast #" .. i, children = {} })
		ConfigGunActionInfo_ReadToLua(unpack(value))
		_set_gun2()
		M.cur_parent = M.calls.children[#M.calls.children]
		M.cur_node = M.cur_parent.children

		_start_shot(mana)
		_draw_actions_for_shot(true)
	end
end

function M.easy_add(id, charges, drained, unlimited_spells)
	for _, v in ipairs(actions) do
		if v.id == id then
			if v.max_uses == nil then
				charges = -1
			elseif unlimited_spells and not v.never_unlimited then
				charges = -1
			elseif charges ~= nil then
				charges = charges
			elseif drained then
				charges = 0
			else
				charges = v.max_uses
			end
			_add_card_to_deck(id, 0, charges, true)
			return
		end
	end
end

return M
