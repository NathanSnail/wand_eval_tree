-- Set up the api we are using

package.path = package.path
	.. ";/home/nathan/Documents/code/AutoLuaAPI/?.lua;/home/nathan/Documents/code/noitadata/?.lua"
require("out")
local print_table = require("print")

function dofile(file)
	return require(file:sub(1, file:len() - 4))
end
dofile_once = dofile

function BeginProjectile(p)
	-- print(p)
end

dofile("data/scripts/gun/gun.lua")

local actions_per_round = 1
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

local function easy_add(id)
	for _, v in ipairs(actions) do
		if v.id == id then
			_add_card_to_deck(id, 0, v.max_uses or -1, true)
			return
		end
	end
end
easy_add("LIGHT_BULLET_TRIGGER_2")
easy_add("LIGHT_BULLET_TRIGGER")
easy_add("LIGHT_BULLET_TRIGGER")
easy_add("LIGHT_BULLET_TRIGGER")
easy_add("LIGHT_BULLET")
easy_add("LIGHT_BULLET")
_start_shot(1000)
_draw_actions_for_shot(true)
calls = calls[1]
print_table(calls)

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
handle(calls, "")
print(out)
