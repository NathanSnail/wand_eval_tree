---@class waker
local M = {}

local ffi = require("ffi")

---0 indexed, 1 indexing is too annoying to work with.
---@param src string
---@param offset integer
---@return integer u32, integer new_offset
local function read_u32(src, offset)
	local val_ptr = ffi.cast("uint32_t *", ffi.new("uint8_t[4]", src:byte(offset + 1, offset + 4)))
	-- [0] will deref, types get confused if we don't assign to a temporary
	return val_ptr[0], offset + 4
end

---0 indexed, 1 indexing is too annoying to work with.
---@param src string
---@param offset integer
---@return string content, integer new_offset
local function read_string(src, offset)
	local length = read_u32(src, offset)
	local substr = src:sub(offset + 5, offset + 4 + length)
	return substr, offset + 4 + length
end

---@param path string
---@return table<string, string>
function M.read_wak(path)
	---@type string
	local src = assert(io.open(path, "r")):read("*a")
	local file_count = read_u32(src, 4)
	local offset = 16
	local files = {}
	for _ = 1, file_count do
		local filename, start, size
		start, offset = read_u32(src, offset)
		size, offset = read_u32(src, offset)
		filename, offset = read_string(src, offset)
		files[filename] = src:sub(start + 1, start + size + 1)
	end

	return files
end

return M
