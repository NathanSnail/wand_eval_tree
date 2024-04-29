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

print("```")
