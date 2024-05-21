---@class mod_interface
local M = {}

function M.load_mods(mod_list)
	for _, v in ipairs(mod_list) do
		dofile("mods/" .. v .. "/init.lua")
	end
end

return M
