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

local function numeric(val, name) end

local arg_fns = {
	spells_per_cast = function(arg)
		local value = tonumber(arg)
		if value then
			return math.floor(value)
		end
		error("argument to spells_per_cast cannot be converted to a number")
	end,
	wand_file = function(arg)
		return arg
	end,
	mana = function() end,
}

if #arg > 0 then
end
