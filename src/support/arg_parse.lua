-- OpenComputers argument parser from loot/openos/lib/shell.lua
-- Modified to support --option=true and --option=false
return function(...)
	local params = table.pack(...)
	local options = {}
	local args = {options = options}
	local doneWithOptions = false
	for i = 1, params.n do
		local param = params[i]
		if not doneWithOptions then
			if param == "--" then
				doneWithOptions = true
			elseif param:sub(1, 2) == "--" then
				if param:match("%-%-(.-)=") ~= nil then
					local key, value = param:match("%-%-(.-)="), param:match("=(.*)")
					if value == "true" or value == "false" then
						options[key] = (value == "true")
					else
						options[key] = value
					end
				else
					options[param:sub(3)] = true
				end
			elseif param:sub(1, 1) == "-" and param ~= "-" then
				for j = 2, #param do
					options[param:sub(j, j)] = true
				end
			else
				table.insert(args, param)
			end
		else
			table.insert(args, param)
		end
	end
	return args, options
end
