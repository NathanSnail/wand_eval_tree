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

text_formatter.set_colours(options.ansi)
fake_engine.evaluate(options)
print(renderer.render(fake_engine.calls, fake_engine, text_formatter, options))
