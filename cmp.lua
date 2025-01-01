-- this script is run when completing and writes newline seperated values to stdout
local cmps = require("arg_parser").complete(arg)

print(table.concat(cmps, "\n"))
