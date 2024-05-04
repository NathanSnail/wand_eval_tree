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

print(options.every_other)
text_formatter.set_colours(options.ansi)
for _, v in ipairs(options.spells) do
	if type(v) == "table" then
		fake_engine.easy_add(v.name, v.count, options.drained)
	else
		fake_engine.easy_add(v, nil, options.drained, options.unlimited_spells)
	end
end

fake_engine.evaluate(options)
print(renderer.render(fake_engine.calls, fake_engine, text_formatter, options))
