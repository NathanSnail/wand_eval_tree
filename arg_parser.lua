local arg_list = {
	a = "ansi",
	d = "drained",
	e = "every_other",
	u = "unlimited_spells",
	t = "tree",
	c = "counts",
	s = "states",
	sc = "spells_per_cast",
	wf = "wand_file",
	ma = "mana",
	rt = "reload_time",
	cd = "cast_delay",
	nc = "number_of_casts",
	ac = "always_casts",
	ml = "mod_list",
	sp = "spells",
}

local defaults = {
	ansi = false,
	drained = false,
	every_other = false,
	unlimited_spells = true,
	tree = true,
	counts = true,
	states = true,
	spells_per_cast = 26,
	wand_file = nil,
	mana = 10000,
	reload_time = 0,
	cast_delay = 0,
	number_of_casts = 1,
	always_casts = {},
	mod_list = {},
	spells = {},
}

---@param val string
---@return boolean
local function boolify(val)
	val = val:lower()
	if val == "y" or val == "true" then
		return true
	elseif val == "n" or val == "false" then
		return false
	end
	error(val .. " is not any of y/n/true/false")
end

local function numeric(name)
	return function(val)
		if val:sub(1, 2) == ".-" then
			val = val:sub(2)
		end
		local value = tonumber(val)
		if value then
			return math.floor(value)
		end
		error("argument to " .. name .. " cannot be converted to a number")
	end
end

local function identity(x)
	return x
end

local function spell_proccess(x)
	local ptr = 1
	local spells = {}
	while ptr <= #x do
		local spell = x[ptr]
		if tonumber(spell) then
			error("invalid spell sequence with number " .. tonumber(spell))
		end
		local next = x[ptr + 1]
		local number = tonumber(next)
		if number then
			spell = { spell, number }
			ptr = ptr + 1
		end
		table.insert(spells, spell)
		ptr = ptr + 1
	end
	return spells
end

---@type table<string, fun(...: any): any>
local arg_fns = {
	spells_per_cast = numeric("spells_per_cast"),
	wand_file = identity,
	mana = numeric("mana"),
	reload_time = numeric("reload_time"),
	cast_delay = numeric("cast_delay"),
	number_of_casts = numeric("number_of_casts"),
	always_casts = spell_proccess,
	mod_list = identity,
	spells = spell_proccess,
}

--[[
options are -... or --...
values that are negative use .- instead of -
arg is an option or a value
single character options are flags, specifying them toggles from the default.
multiple flags can be specified like -abc, it must not be followed by a value.
you can also specify flags fully with -a true
other values can be specified like -ma 1000, or --mods grahams_perks boss_reworks
if no options are specified the -sp option is automatically added to the start
]]

---@nodiscard
---@param option string
---@param value string[]
---@return any, string
local function apply_option(option, value)
	local short_flag = option:sub(2, 2) ~= "-"
	if short_flag then
		local longer = arg_list[option:sub(2)]
		if not longer then
			error("unknown short flag " .. option)
		end
		option = longer
	else
		option = option:sub(3)
	end
	if not arg_fns[option] then
		if defaults[option] ~= nil then
			return boolify(value[1]), option
		end
		error("unknown option " .. option)
	end
	return arg_fns[option](value), option
end

---@class arg_parser
local M = {}

---@class (exact) formatter_options
---@field ansi boolean
---@field drained boolean
---@field every_other boolean
---@field unlimited_spells boolean
---@field tree boolean
---@field counts boolean
---@field states boolean
---@field spells_per_cast integer
---@field wand_file string?
---@field mana integer
---@field reload_time integer
---@field cast_delay integer
---@field number_of_casts integer
---@field always_casts string[]
---@field mod_list string[]
---@field spells string[]

---@param args string[]
---@return formatter_options
function M.parse(args)
	local cur_options = {}
	for k, v in pairs(defaults) do
		cur_options[k] = v
	end

	if #args == 0 then
		return defaults
	end
	local ptr = 1
	local contains_opts = false
	for _, v in ipairs(args) do
		contains_opts = contains_opts or v:sub(1, 1) == "-"
	end
	if not contains_opts then
		cur_options.spells = apply_option("--spells", args)
		return cur_options
	end
	while ptr <= #args do
		local cur_arg = args[ptr]
		local is_opt = cur_arg:sub(1, 1) == "-"
		local is_long_opt = cur_arg:sub(2, 2) == "-"
		local is_short_opt = is_opt and not is_long_opt
		local next_arg = args[ptr + 1]
		local next_arg_is_opt = false
		if next_arg then
			next_arg_is_opt = (next_arg:sub(1, 1) == "-")
		end
		local flag_block = is_short_opt and (not next_arg or next_arg_is_opt)
		if flag_block then
			for i = 2, #cur_arg do
				local flag_char = cur_arg:sub(i, i)
				local full_name = arg_list[flag_char]
				if defaults[full_name] == nil then
					error("unknown flag " .. flag_char)
				end
				cur_options[full_name] = not defaults[full_name]
			end
		elseif is_opt then
			local parameter_list = {}
			ptr = ptr + 1
			while ptr <= #args do
				local cur = args[ptr]
				if cur:sub(1, 1) == "-" then
					ptr = ptr - 1
					break
				end
				ptr = ptr + 1
				table.insert(parameter_list, cur)
			end
			local value, name = apply_option(cur_arg, parameter_list)
			cur_options[name] = value
		else
			error("stray value " .. cur_arg)
		end
		ptr = ptr + 1
	end
	return cur_options
end

return M
