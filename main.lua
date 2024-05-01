local fake_engine = require("fake_engine")
---@type renderer
local renderer = require("renderer")
local text_formatter = require("text_formatter")
print_table = require("print")
---@type arg_parser
local arg_parser = require("arg_parser")
local options = arg_parser.parse(arg)
--print_table(options)
fake_engine.initialise_engine(text_formatter)

if options then
	text_formatter.colours = options.ansi
	for k, v in ipairs(options.spells) do
		if type(v) == "table" then
			fake_engine.easy_add(v[1], v[2], options.drained)
		else
			if options.drained then
				fake_engine.easy_add(v, 0, true)
			else
				fake_engine.easy_add(v)
			end
		end
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
print(renderer.render(fake_engine.calls, fake_engine, text_formatter))
