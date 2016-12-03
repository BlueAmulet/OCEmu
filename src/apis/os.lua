local env = ...

env.os = setmetatable({},{
	__index = function(_,k)
		cprint("Missing environment access", "env.os." .. k)
	end,
})

env.os.clock = os.clock
env.os.time = os.time

-- Valid: %ABCDFHIMRSTXYabcdehjmnprtwxy
-- Windows: CDFRTehnrt
local mapping = {["\0"]="%%"}
local gsubmap
local passthrough = "%ABHIMSXYabcdjmpwxy"
if elsa.system.getOS() == "Windows" then
	mapping["C"] = function() return string.format("%02d", os.date("*t").year/100) end
	mapping["D"] = "%m/%d/%y"
	mapping["F"] = "%Y-%m-%d"
	mapping["R"] = "%H:%M"
	mapping["T"] = "%H:%M:%S"
	mapping["e"] = function() return string.format("% 2d", os.date("*t").day) end
	mapping["h"] = "%b"
	mapping["n"] = "\n"
	mapping["r"] = "%I:%M:%S %p"
	mapping["t"] = "\t"
	function gsubmap(a)
		local map=mapping[a]
		if type(map) == "function" then
			return map()
		elseif map then
			return map
		else
			return ""
		end
	end
else
	passthrough = passthrough .. "CDFRTehnrt"
	function gsubmap(a) return mapping[a] or "" end
end
for i = 1, #passthrough do
	local char = passthrough:sub(i, i)
	mapping[char] = "%" .. char
end

function env.os.date(format, ...)
	local ftype = type(format)
	if ftype ~= "string" and ftype ~= "number" then
		return os.date("%d/%m/%y %H:%M:%S", ...)
	elseif ftype == "number" then
		return tostring(format)
	end
	format=format:gsub("%%(.)", gsubmap)
	if format:sub(1, 1) == "!" then
		format = format:sub(2)
	end
	return os.date(format, ...)
end
