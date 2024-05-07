---@class mod_interface
local M = {}

local function load_mod(name)
	dofile("mods/" .. name .. "/init.lua")
end

function M.load_mods(mod_list)
	for k, v in ipairs(mod_list) do
		load_mod(v)
	end
end

return M
