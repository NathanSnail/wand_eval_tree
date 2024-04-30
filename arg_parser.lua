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
		local value = tonumber(val)
		if value then
			return math.floor(value)
		end
		error("argument to " .. name .. " cannot be converted to a number")
	end
end

local function identity(...)
	return table.unpack({ ... })
end

local function single_identity(x)
	return x
end

---@type table<string, fun(...: any): any>
local arg_fns = {
	spells_per_cast = numeric("spells_per_cast"),
	wand_file = single_identity,
	mana = numeric("mana"),
	reload_time = numeric("reload_time"),
	cast_delay = numeric("cast_delay"),
	number_of_casts = numeric("number_of_casts"),
	always_casts = identity,
	mod_list = identity,
}

local cur_options = {}
for k, v in pairs(defaults) do
	cur_options[k] = v
end

--[[
single character options are flags, specifying them toggles from the default.
multiple flags can be specified like -abc, it must not be followed by a value.
you can also specify flags fully with -a true
other values can be specified like -ma 1000, or --mods grahams_perks boss_reworks
just use - with nothing else to specify the spells argument
if the first arg is a value - is inserted automatically
]]

---@param flag string
---@param value boolean?
local function apply_flag(flag, value)
	local short_flag = flag:sub(2, 2) ~= "-"
	if short_flag then
		local longer = arg_list[flag:sub(2)]
		if not longer then
			error("unknown short flag " .. flag)
		end
		flag = longer
	else
		flag = flag:sub(3)
	end
	if value == nil then
		local default = defaults[flag]
		if type(default) == "boolean" then
			value = not default
		else
			error("flag " .. flag .. " requires a value")
		end
	end
	cur_options[flag] = arg_fns[flag](value)
end

if #arg > 0 then
	local ptr = 1
	while ptr <= #arg do
		local cur_arg = arg[ptr]
		local is_opt = cur_arg:sub(1, 1) == "-"
		local is_long_opt = cur_arg:sub(2, 2) == "-"
		local next_arg = arg[ptr + 1]
		local next_arg_is_opt
		if next_arg then
			next_arg_is_opt = (next_arg:sub(1, 1) == "-")
		end
		local flag_block = is_opt and not is_long_opt and next_arg_is_opt
		if flag_block then
			for i = 2, #cur_arg do
				local flag_char = cur_arg:sub(i, i)
			end
		end
	end
end
