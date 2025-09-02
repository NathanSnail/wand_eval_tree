-- Set up the api we are using

---@type entropy
local entropy = require("src.entropy")

---@type prng
local prng = require("src.prng")

---@class (exact) shot_ref
---@field state state
---@field num_of_cards_to_draw integer

---@diagnostic disable-next-line: unused-function
local function dbg_cards(pile)
	for _, v in ipairs(pile) do
		print(v.id)
	end
end
---@diagnostic disable-next-line: unused-function, unused-local
local function dbg_wand()
	print("discard")
	dbg_cards(discarded)
	print("hand")
	dbg_cards(hand)
	print("deck")
	dbg_cards(deck)
end

---@param text_formatter text_formatter
---@param id string
local function bad_spell(text_formatter, id)
	error(
		text_formatter.colour_codes.RED
			.. "Unknown spell "
			.. text_formatter.colour_codes.RESET
			.. '"'
			.. text_formatter.colour_codes.GREEN
			.. id
			.. text_formatter.colour_codes.RESET
			.. '"'
	)
end

---@param text_formatter text_formatter
---@param id string
local function is_bad(text_formatter, id)
	for _, v in ipairs(actions) do
		if v.id == id then return end
	end
	bad_spell(text_formatter, id)
end

---@param id string
---@param charges integer?
---@param options options
---@param text_formatter text_formatter
local function easy_add(id, charges, options, text_formatter)
	id = id:upper()
	for _, v in ipairs(actions) do
		if v.id:upper() == id then
			if v.max_uses == nil then
				charges = -1
			elseif options.unlimited_spells and not v.never_unlimited then
				charges = -1
			elseif charges ~= nil then -- at this point we use the arg
			elseif options.drained then
				charges = 0
			else
				charges = v.max_uses
			end
			---@cast charges integer
			_add_card_to_deck(id, 0, charges, true)
			local card = deck[#deck]
			---@diagnostic disable-next-line: missing-parameter, assign-type-mismatch, param-type-mismatch
			card.action = card.action(card)
			return
		end
	end
	bad_spell(text_formatter, id)
end

---@class fake_engine
local M = {}

---@param options options
local function regenerate_translations(options)
	-- print(ModTextFileGetContent("data/translations/common.csv"))
	local actual_translations = {}
	local tcsv = require("extra.tcsv")
	local csv =
		---@diagnostic disable-next-line: param-type-mismatch
		tcsv.parse(ModTextFileGetContent("data/translations/common.csv"), "common.csv", false)
	local csv_lang_row = nil
	for k, v in ipairs(csv.langs) do
		if v == options.language then csv_lang_row = k + 1 end
	end
	for _, v in ipairs(csv.rows) do
		actual_translations[v[1]] = v[csv_lang_row]
	end
	function GameTextGetTranslatedOrNot(text_or_key)
		if text_or_key:sub(1, 1) == "$" then
			return actual_translations[text_or_key:sub(2)] or text_or_key
		end
		return text_or_key
	end

	for _, v in ipairs(actions or {}) do
		if options.language then
			M.translations[v.id] = GameTextGetTranslatedOrNot(v.name)
			--print(v.id, v.name, GameTextGetTranslatedOrNot(v.name))
			--print(v.name:len())
		end
	end
end

M.noita_path = ""
M.data_path = ""

---@param options options
function M.make_fake_api(options)
	package.path = package.path .. ";" .. M.data_path .. "?.lua;" .. M.noita_path .. "?.lua"
	M.vfs = {
		["data/translations/common.csv"] = assert(
			assert(io.open(M.noita_path .. "data/translations/common.csv", "r")):read("*a")
		),
	}
	---@type table<string, any>
	M.mod_settings = {}
	local _print = print
	require("meta.out")
	print = _print

	regenerate_translations(options)

	local frame = entropy.get_entropy()
	prng.set_seed(frame)
	math.randomseed(frame)
	function Random(a, b)
		if not a and not b then return math.random() end
		if not b then
			b = a
			a = 0
		end
		return math.floor(math.random() * (b - a + 1)) + a
	end

	local globals = {}
	local append_map = {}

	function GlobalsSetValue(key, value)
		globals[key] = tostring(value)
	end

	function ModTextFileGetContent(filename)
		local success, res = pcall(function()
			if M.vfs[filename] then return M.vfs[filename] end
			if filename:sub(1, 4) == "mods" then
				return assert(assert(io.open(M.noita_path .. filename)):read("*a"))
			end
			for _, mod in ipairs(options.mods) do
				local data_filed = io.open(M.noita_path .. "mods/" .. mod .. "/" .. filename)
				if data_filed then M.vfs[filename] = data_filed:read("*a") end
			end
			-- recheck for mod /data/
			if M.vfs[filename] then return M.vfs[filename] end
			return assert(assert(io.open(M.data_path .. filename)):read("*a"))
		end)
		if not success then return nil end
		return res
	end

	function ModTextFileSetContent(filename, new_content)
		M.vfs[filename] = new_content
		if filename == "data/translations/common.csv" then regenerate_translations(options) end
	end

	function GlobalsGetValue(key, value)
		return tostring(globals[key] or value)
	end

	function SetRandomSeed(x, y)
		math.randomseed(x * 591.321 + y * 8541.123 + 124.545)
	end

	function GameGetFrameNum()
		return frame
	end

	function ModLuaFileAppend(to, from)
		append_map[to] = append_map[to] or {}
		table.insert(append_map[to], from)
	end

	function ModSettingSet(id, value)
		M.mod_settings[id] = value
	end

	function ModSettingGet(id)
		return M.mod_settings[id]
	end

	ModSettingGetNextValue = ModSettingGet
	ModSettingSetNextValue = ModSettingSet

	function dofile(file)
		local content = ModTextFileGetContent(file)
		if not content then
			error(
				"Could not dofile `"
					.. file
					.. "` because it does not exist in the VFS! perhaps your paths are wrong?"
			)
		end
		local res = { loadstring(content, file)() }
		for _, v in ipairs(append_map[file] or {}) do
			dofile(v)
		end
		return unpack(res)
	end
	dofile_once = dofile

	dofile("data/scripts/gun/gun_enums.lua")

	--[[function BeginProjectile(p)
		print(p)
	end]]
end

---@param text_formatter text_formatter
---@param options options
function M.initialise_engine(text_formatter, options)
	dofile("data/scripts/gun/gun.lua")
	local _create_shot = create_shot
	function create_shot(...)
		local uv = { _create_shot(...) }
		local v = uv[1]
		M.nodes_to_shot_ref[M.cur_parent] = v
		M.shot_refs_to_nums[v] = { disp = M.cur_shot_num, real = M.cur_shot_num }
		M.cur_shot_num = M.cur_shot_num + 1
		-- v.state.wand_tree_initial_mana = mana
		-- TODO: find a way to do this in a garunteed safe way
		return unpack(uv)
	end

	function StartReload(reload_time)
		M.reload_time = reload_time
	end

	--[[local _draw_shot = draw_shot
	function draw_shot(...)
		local v = { _draw_shot(...) }
		local args = { ... }
		local shot = args[1]
		shot.state.wand_tree_mana = mana - shot.state.wand_tree_initial_mana
		shot.state.wand_tree_initial_mana = nil
		return unpack(v)
	end]]

	M.translations = {}
	for _, v in ipairs(actions) do
		text_formatter.ty_map[v.id] = v.type
		local _a = v.action
		v.action = function(clone, ...)
			local new = function(...)
				---@cast clone action
				local old_node = M.cur_node
				local new_node = { name = v.id, children = {}, index = clone.deck_index }
				M.counts[v.id] = (M.counts[v.id] or 0) + 1
				M.cur_node = new_node.children
				M.cur_parent = new_node
				table.insert(old_node, new_node)
				local res = { _a(...) }
				M.cur_node = old_node
				return unpack(res)
			end
			if type(clone) == "table" then -- this is awful
				---@diagnostic disable-next-line: return-type-mismatch
				return new
			end
			clone = { deck_index = -1 }
			---@diagnostic disable-next-line: redundant-return-value
			return unpack({ new(...) })
		end
	end
	regenerate_translations(options)
end

---@param options options
---@param text_formatter text_formatter
---@param read_to_lua_info table
---@param cast integer
local function eval_wand(options, text_formatter, read_to_lua_info, cast)
	mana = math.min(mana, options.mana_max)
	table.insert(M.calls.children, { name = "Cast #" .. cast, children = {} })
	ConfigGunActionInfo_ReadToLua(unpack(read_to_lua_info))
	_set_gun2()
	M.cur_parent = M.calls.children[#M.calls.children]
	local cur_root = M.cur_parent
	M.cur_node = M.cur_parent.children

	local old_mana = mana
	_start_shot(mana)
	for k, v in ipairs(options.always_casts) do
		if type(v) == "table" then v = v.name end
		---@cast v string
		is_bad(text_formatter, v)
		---@cast v string
		--[[local s = "set_current_action"
			local _c = _G[s]
			_G[s] = function(...)
				for _, v2 in ipairs({ ... }) do
					print_table(v2)
				end
				_c(...)
			end]]
		local _clone_action = clone_action
		clone_action = function(...)
			local res = { _clone_action(...) }
			local dest = ({ ... })[2]
			local old_action = dest.action
			dest.action = function(...)
				local action_res = { old_action({ deck_index = -k })(...) }
				return unpack(action_res)
			end
			clone_action = _clone_action
			return unpack(res)
		end
		_play_permanent_card(v)
		--_G[s] = _c
	end
	_draw_actions_for_shot(true)
	--dbg_wand()
	local delay = root_shot.state.fire_rate_wait

	-- cursed nolla design.
	_handle_reload()
	if M.reload_time then
		delay = math.max(delay, M.reload_time)
		M.reload_time = nil
	end
	delay = math.max(delay, 1)
	cur_root.extra = "Delay: " .. delay .. "f, ΔMana: " .. (old_mana - mana)
	mana = mana + delay * options.mana_charge / 60
end

---@param options options
---@param text_formatter text_formatter
---@param spells spell[]
---@return table read_to_lua_info the info describing what to pass to the fake lua side from engine
local function reset_wand(options, text_formatter, spells)
	---@type node
	M.calls = { name = "Wand", children = {} }
	M.nodes_to_shot_ref = {}
	M.shot_refs_to_nums = {}
	M.lines_to_shot_nums = {}
	M.cur_shot_num = 1
	---@type table<string, integer>
	M.counts = {}

	_clear_deck(false)
	for _, v in ipairs(spells) do
		if type(v) == "string" then
			easy_add(v, nil, options, text_formatter)
		else
			easy_add(v.name, v.count, options, text_formatter)
		end
	end

	ConfigGun_ReadToLua(options.spells_per_cast, false, options.reload_time, 66)
	_set_gun()
	local data = require("src.data")
	local arg_list = require("src.arg_list")
	data.fire_rate_wait = options.cast_delay
	local read_to_lua_info = {}
	for _, v in ipairs(arg_list) do
		table.insert(read_to_lua_info, data[v])
	end

	mana = options.mana
	GlobalsSetValue("GUN_ACTION_IF_HALF_STATUS", options.every_other and 1 or 0)

	return read_to_lua_info
end

---@param options options
---@param text_formatter text_formatter
local function fuzz(options, text_formatter)
	options.fuzz_out = options.fuzz_out or {}
	options.fuzz_minimise = options.fuzz_minimise or {}
	options.fuzz_maximise = options.fuzz_maximise or {}

	if not (options.fuzz_pool and options.fuzz_target and options.fuzz_size) then
		error(
			"Some fuzzing options are set but not all, you must specify all fuzz options (other than out / min / max) or none"
		)
	end

	for _, constraint in ipairs(options.fuzz_target) do
		for _, v in ipairs(actions) do
			if v.id == constraint.spell then goto success end
		end
		bad_spell(text_formatter, constraint.spell)
		::success::
	end

	local run = 1
	local notable_run = 1000
	while true do
		local spells = {}
		for _ = 1, options.fuzz_size do
			local spell_choice = 1 + (prng.get_random_32() % #options.fuzz_pool)
			table.insert(spells, options.fuzz_pool[spell_choice])
		end
		local read_to_lua_info = reset_wand(options, text_formatter, spells)
		for i = 1, options.number_of_casts do -- you can fuzz multiple casts i suppose
			eval_wand(options, text_formatter, read_to_lua_info, i)
		end

		local failed = false
		for _, requirement in ipairs(options.fuzz_target) do
			local count = M.counts[requirement.spell]
			if not (count and count >= requirement.low and count <= requirement.high) then
				failed = true
				break
			end
		end

		if not failed then
			-- mutate the constraints to be stricter
			for _, constraint in ipairs(options.fuzz_target) do
				-- we dont need to do min/max because our constraint is neccesarily as strict as the old one
				for _, maximise in ipairs(options.fuzz_maximise) do
					if constraint.spell == maximise then
						constraint.low = M.counts[constraint.spell]
					end
				end

				for _, minimise in ipairs(options.fuzz_minimise) do
					if constraint.spell == minimise then
						constraint.high = M.counts[constraint.spell]
					end
				end
			end

			local str = ""
			for _, out in ipairs(options.fuzz_out) do
				local count = M.counts[out]
				str = str
					.. " "
					.. text_formatter.id_text(out, M.translations)
					.. text_formatter.colour_codes.RESET
					.. "="
					.. count
			end
			for _, spell in ipairs(spells) do
				str = str .. " " .. text_formatter.id_text(spell, M.translations)
			end
			str = str:sub(2) .. text_formatter.colour_codes.RESET
			print(run .. ": " .. str)
		end

		if run == notable_run then
			print(run)
			notable_run = notable_run * 5
		end
		run = run + 1
	end
end

---@param options options
---@param text_formatter text_formatter
function M.evaluate(options, text_formatter)
	if
		options.fuzz_pool
		or options.fuzz_target
		or options.fuzz_size
		or options.fuzz_out
		or options.fuzz_minimise
		or options.fuzz_maximise
	then
		fuzz(options, text_formatter)
	end

	local read_to_lua_info = reset_wand(options, text_formatter, options.spells)
	for i = 1, options.number_of_casts do
		eval_wand(options, text_formatter, read_to_lua_info, i)
	end
end

return M
