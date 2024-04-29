local fake_engine = require("fake_engine")
---@type renderer
local renderer = require("renderer")
local text_formatter = require("text_formatter")
fake_engine.initialise_engine(text_formatter)

if #arg > 0 then
	local p = 1
	local zerod = false
	if arg[p] == "-c" or arg[p + 1] == "-c" then
		zerod = true
		p = p + 1
	end
	if arg[p] == "-a" or arg[p + 1] == "-a" then
		p = p + 1
		text_formatter.colours = true
	end
	while p <= #arg do
		if tonumber(arg[p + 1]) then
			fake_engine.easy_add(arg[p], tonumber(arg[p + 1]), zerod)
			p = p + 1
		else
			if zerod then
				fake_engine.easy_add(arg[p], 0, true)
			else
				fake_engine.easy_add(arg[p])
			end
		end
		p = p + 1
	end
else
	text_formatter.colours = true
	fake_engine.easy_add("ADD_TRIGGER")
	fake_engine.easy_add("LIGHT_BULLET")
	fake_engine.easy_add("HOMING")
	fake_engine.easy_add("BLOOD_MAGIC")
	fake_engine.easy_add("LIGHT_BULLET")
	fake_engine.easy_add("ADD_TRIGGER")
	fake_engine.easy_add("LIGHT_BULLET")
	fake_engine.easy_add("HOMING")
	fake_engine.easy_add("BLOOD_MAGIC")
	fake_engine.easy_add("LIGHT_BULLET")
	fake_engine.easy_add("ADD_TRIGGER")
	fake_engine.easy_add("LIGHT_BULLET")
	fake_engine.easy_add("HOMING")
	fake_engine.easy_add("BLOOD_MAGIC")
	fake_engine.easy_add("LIGHT_BULLET")
end

fake_engine.evaluate(26, false, 0, 26, 1000000)
renderer.render(fake_engine.calls, fake_engine, text_formatter)
