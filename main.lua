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

local calls = {}
local cur_node = calls
for _, v in ipairs(actions) do
	local _a = v.action
	v.action = function(...)
		local old_node = cur_node
		local new_node = { v.id, {} }
		cur_node = new_node[2]
		table.insert(old_node, new_node)
		_a(...)
		cur_node = old_node
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

ConfigGunActionInfo_ReadToLua(
	unpack(value)
	--action_id,
	--action_name,
	--action_description,
	--action_sprite_filename,
	--action_unidentified_sprite_filename,
	--action_type,
	--action_spawn_level,
	--action_spawn_probability,
	--action_spawn_requires_flag,
	--action_spawn_manual_unlock,
	--action_max_uses,
	--custom_xml_file,
	--action_mana_drain,
	--action_is_dangerous_blast,
	--action_draw_many_count,
	--action_ai_never_uses,
	--action_never_unlimited,
	--state_shuffled,
	--state_cards_drawn,
	--state_discarded_action,
	--state_destroyed_action,
	--fire_rate_wait,
	--speed_multiplier,
	--child_speed_multiplier,
	--dampening,
	--explosion_radius,
	--spread_degrees,
	--pattern_degrees,
	--screenshake,
	--recoil,
	--damage_melee_add,
	--damage_projectile_add,
	--damage_electricity_add,
	--damage_fire_add,
	--damage_explosion_add,
	--damage_ice_add,
	--damage_slice_add,
	--damage_healing_add,
	--damage_curse_add,
	--damage_drill_add,
	--damage_null_all,
	--damage_critical_chance,
	--damage_critical_multiplier,
	--explosion_damage_to_materials,
	--knockback_force,
	--reload_time,
	--lightning_count,
	--material,
	--material_amount,
	--trail_material,
	--trail_material_amount,
	--bounces,
	--gravity,
	--light,
	--blood_count_multiplier,
	--gore_particles,
	--ragdoll_fx,
	--friendly_fire,
	--physics_impulse_coeff,
	--lifetime_add,
	--sprite,
	--extra_entities,
	--game_effect_entities,
	--sound_loop_tag,
	--projectile_file
)
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
			easy_add(arg[p])
		end
		p = p + 1
	end
else
	--[[easy_add("LIGHT_BULLET_TRIGGER")
	easy_add("BURST_3")
	easy_add("ADD_TRIGGER")
	easy_add("ADD_TRIGGER")
	easy_add("ADD_TRIGGER")
	easy_add("DAMAGE")
	easy_add("HOMING")
	easy_add("BALL_LIGHTNING")
	easy_add("BLACK_HOLE", 0)]]
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
			print_table(v)
			print(i)
			if i ~= 1 then
				node[2][i - 1][3] = cur_c
				cur_c = 1
			end
			i = i + 1
		end
	end
	return node
end

print_table(flatten({
	"HAMIS",
	{ { "SPAR BOL", {} }, { "NUKES!", { { "THING", {} } } }, { "NUKES!", { { "THING", {} } } }, { "HAMIS2", {} } },
}))

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
	out = out .. t_prefix .. node[1] .. "\n"
	for k, v in ipairs(node[2]) do
		local dont = k == #node[2]
		if no_extra then
			prefix = prefix:sub(1, prefix:len() - 1) .. " "
		end
		handle(v, prefix .. "#", dont)
	end
end
handle({ "WAND", calls }, "")
if #arg ~= 0 then
	out = "```\n" .. out .. "```"
end
print(out)
