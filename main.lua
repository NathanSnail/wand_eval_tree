if #arg > 0 then
	local p = 1
	local zerod = false
	if arg[p] == "-c" or arg[p + 1] == "-c" then
		zerod = true
		p = p + 1
	end
	if arg[p] == "-a" or arg[p + 1] == "-a" then
		p = p + 1
		colours = true
	end
	while p <= #arg do
		if tonumber(arg[p + 1]) then
			easy_add(arg[p], tonumber(arg[p + 1]), zerod)
			p = p + 1
		else
			if zerod then
				easy_add(arg[p], 0, true)
			else
				easy_add(arg[p])
			end
		end
		p = p + 1
	end
else
	colours = true
	easy_add("ADD_TRIGGER")
	easy_add("LIGHT_BULLET")
	easy_add("HOMING")
	easy_add("BLOOD_MAGIC")
	easy_add("LIGHT_BULLET")
	easy_add("ADD_TRIGGER")
	easy_add("LIGHT_BULLET")
	easy_add("HOMING")
	easy_add("BLOOD_MAGIC")
	easy_add("LIGHT_BULLET")
	easy_add("ADD_TRIGGER")
	easy_add("LIGHT_BULLET")
	easy_add("HOMING")
	easy_add("BLOOD_MAGIC")
	easy_add("LIGHT_BULLET")
end
_start_shot(10000000)
_draw_actions_for_shot(true)

flatten(calls)
local out = ""

local function pre_multiply(node, val)
	node[3] = node[3] * val
	for _, v in ipairs(node[2]) do
		pre_multiply(v, node[3])
	end
end

local function len(str)
	return str:gsub("[\128-\191]", ""):len()
end

local bars = { { 1, 0, 0, 1 } }
local function post_multiply()
	local bar_idx = 1
	local out_sp = {}
	for str in out:gmatch("([^\n]+)") do
		table.insert(out_sp, str)
	end
	for k, str in ipairs(out_sp) do
		local colourless = str:gsub(string.char(27) .. ".-m", "")
		if bars[bar_idx][2] < k then
			bar_idx = bar_idx + 1
		end
		bars[bar_idx][3] = math.max(bars[bar_idx][3], len(colourless))
	end
	bar_idx = 1
	for k, str in ipairs(out_sp) do
		local colourless = str:gsub(string.char(27) .. ".-m", "")
		if bars[bar_idx][2] < k then
			bar_idx = bar_idx + 1
		end
		local extra = (" "):rep(bars[bar_idx][3] - len(colourless) + 1)
		if bars[bar_idx][1] == bars[bar_idx][2] then
			extra = extra .. "]"
		elseif bars[bar_idx][1] == k then
			extra = extra .. "┐"
		elseif bars[bar_idx][2] == k then
			extra = extra .. "┘"
		else
			extra = extra .. "│"
		end
		if math.floor((bars[bar_idx][1] + bars[bar_idx][2]) / 2) == k then
			extra = extra
				.. " "
				.. (colours and (string.char(27) .. "[37m") or "")
				.. bars[bar_idx][4]
				.. (colours and (string.char(27) .. "[30m") or "")
		end
		if bars[bar_idx][4] ~= 1 then
			out_sp[k] = out_sp[k] .. extra
		end
		if lines_to_shot_nums[k] then
			out_sp[k] = out_sp[k]
				.. " @ "
				.. (colours and (string.char(27) .. "[0m") or "")
				.. table.concat(lines_to_shot_nums[k], ", ")
				.. (colours and (string.char(27) .. "[30m") or "")
		end
	end
	out = table.concat(out_sp, "\n")
end

local function handle(node, prefix, no_extra, indent_level)
	indent_level = indent_level or 0
	local t_prefix = ""
	for k = 1, prefix:len() do
		local v = prefix:sub(k, k)
		if v == "#" then
			t_prefix = t_prefix .. (k == prefix:len() and (no_extra and "└" or "├") or "│")
		else
			t_prefix = t_prefix .. " "
		end
	end
	out = out
		.. t_prefix
		.. id_text(node[1])
		--[[.. (node[3] ~= 1 and ((colours and (string.char(27) .. "[37m") or "") .. " (" .. node[3] .. ")" .. (colours and (string.char(
			27
		) .. "[30m") or "")) or "")]]
		.. "\n"
	if nodes_to_shot_ref[node] then
		local _, c = out:gsub("\n", "\n")
		local cur_line = {}
		if nodes_to_shot_ref[node] then
			cur_line[1] = nodes_to_shot_ref[node]
		end
		for k, v in ipairs(cur_line) do
			cur_line[k] = shot_refs_to_nums[v]
		end
		lines_to_shot_nums[c] = cur_line
	end
	if bars[#bars][3] <= indent_level and bars[#bars][4] == node[3] then
		bars[#bars][2] = bars[#bars][2] + 1
	else
		bars[#bars + 1] = { bars[#bars][2] + 1, bars[#bars][2] + 1, indent_level, node[3] }
	end
	for k, v in ipairs(node[2]) do
		local dont = k == #node[2]
		if no_extra then
			prefix = prefix:sub(1, prefix:len() - 1) .. " "
		end
		handle(v, prefix .. "#", dont, indent_level + 1)
	end
end

--print_table(nodes_to_shot_ref)
pre_multiply(calls, 1)
handle(calls, "")
post_multiply()
out = (colours and "```ansi\n" or "") .. out
print(out)

local count_pairs = {}
local big_length = 0
local big_length2 = 0
for k, v in pairs(counts) do
	table.insert(count_pairs, { k, tostring(v), v })
	big_length = math.max(big_length, k:len())
	big_length2 = math.max(big_length2, tostring(v):len())
end
table.sort(count_pairs, function(a, b)
	if a[3] ~= b[3] then
		return a[3] > b[3]
	end
	if col_map[ty_map[a[1]]] ~= col_map[ty_map[b[1]]] then
		return col_map[ty_map[a[1]]] > col_map[ty_map[b[1]]]
	end
	return a[1] > b[1]
end)
local count_message = "┌" .. ("─"):rep(big_length + 2) .. "┬" .. ("─"):rep(big_length2 + 2) .. "┐\n"
for _, v in ipairs(count_pairs) do
	count_message = count_message
		.. "│ "
		.. id_text(v[1])
		.. (" "):rep(big_length - v[1]:len() + 1)
		.. "│ "
		.. (colours and (string.char(27) .. "[0m") or "")
		.. v[2]
		.. (colours and (string.char(27) .. "[30m") or "")
		.. (" "):rep(big_length2 - v[2]:len() + 1)
		.. "│\n"
end
count_message = count_message
	.. "└"
	.. ("─"):rep(big_length + 2)
	.. "┴"
	.. ("─"):rep(big_length2 + 2)
	.. "┘\n"
print(count_message)

local function gather_state_modifications(state, first)
	local default = require("data")
	local diff = {}
	for k, v in pairs(state) do
		if default[k] ~= v then
			diff[k] = v
		end
	end
	diff.action_name = nil
	diff.action_id = nil
	diff.action_mana_drain = nil
	diff.action_draw_many_count = nil
	diff.reload_time = nil
	if not first then
		diff.fire_rate_wait = nil
	end
	diff.extra_entities = diff.extra_entities or ""
	---@type string[]
	local mods = {}
	for mod in diff.extra_entities:gmatch("([^,]+)") do
		table.insert(mods, mod)
	end
	for k, mod in ipairs(mods) do
		local suffix = mod:gmatch("/[^/]+%.xml")()
		mods[k] = suffix:sub(2, suffix:len() - 4)
	end
	local counted = {}
	for _, v in ipairs(mods) do
		counted[v] = (counted[v] or 0) + 1
	end
	local numeric = {}
	for k, v in pairs(counted) do
		table.insert(numeric, k .. (v == 1 and "" or (" ×" .. tostring(v))))
	end
	diff.extra_entities = table.concat(numeric, ", ")
	if diff.extra_entities == "" then
		diff.extra_entities = nil
	end
	return diff
end
local shot_nums_to_refs = {}

for shot, num in pairs(shot_refs_to_nums) do
	shot_nums_to_refs[num] = shot, num
end
for num, shot in ipairs(shot_nums_to_refs) do
	local shot_table = (colours and (string.char(27) .. "[0m") or "") .. "Shot state " .. num .. ":\n"
	local diff = gather_state_modifications(shot.state, num == 1)
	local name_width = 0
	local value_width = 0
	for k, v in pairs(diff) do
		name_width = math.max(name_width, k:len())
		value_width = math.max(value_width, tostring(v):len())
	end
	name_width = name_width + 2
	value_width = value_width + 2
	shot_table = shot_table
		.. (colours and (string.char(27) .. "[30m") or "")
		.. "┌"
		.. ("─"):rep(name_width)
		.. "┬"
		.. ("─"):rep(value_width)
		.. "┐\n"
	for k, v in pairs(diff) do
		local v_str = tostring(v)
		shot_table = shot_table
			.. "│ "
			.. (colours and (string.char(27) .. "[0m") or "")
			.. k
			.. (colours and (string.char(27) .. "[30m") or "")
			.. (" "):rep(name_width - k:len() - 1)
			.. "│ "
			.. (colours and (string.char(27) .. "[0m") or "")
			.. v_str
			.. (colours and (string.char(27) .. "[30m") or "")
			.. (" "):rep(value_width - len(v_str) - 1)
			.. "│\n"
	end
	shot_table = shot_table .. "└" .. ("─"):rep(name_width) .. "┴" .. ("─"):rep(value_width) .. "┘\n"

	print(shot_table)
end
print("```")
