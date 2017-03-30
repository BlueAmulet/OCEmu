local env = ...

local utf8 = require("lua-utf8")

env.unicode = setmetatable({},{
	__index = function(_,k)
		cprint("Missing environment access", "env.unicode." .. k)
	end,
})

function env.unicode.char(...)
	cprint("unicode.char", ...)
	local args = table.pack(...)
	for i = 1,args.n do
		checkArg(i,args[i],"number")
		args[i] = args[i]%0x10000
	end
	return utf8.char(table.unpack(args))
end
function env.unicode.lower(str)
	cprint("unicode.lower", str)
	if type(str) == "number" then str = tostring(str) end
	checkArg(1,str,"string")
	return utf8.lower(str)
end
function env.unicode.upper(str)
	cprint("unicode.upper", str)
	if type(str) == "number" then str = tostring(str) end
	checkArg(1,str,"string")
	return utf8.upper(str)
end
function env.unicode.len(str)
	cprint("unicode.len", str)
	checkArg(1,str,"string")
	return utf8.len(str)
end
function env.unicode.reverse(str)
	cprint("unicode.reverse", str)
	checkArg(1,str,"string")
	return utf8.reverse(str)
end
function env.unicode.sub(str, i, j)
	cprint("unicode.isWide", str)
	checkArg(1,str,"string")
	checkArg(2,i,"number")
	if j == nil then j = -1 end
	checkArg(3,j,"number")
	return utf8.sub(str,i,j)
end
function env.unicode.isWide(str)
	cprint("unicode.isWide", str)
	checkArg(1,str,"string")
	if #str == 0 then
		error("String index out of range: 0", 0)
	end
	local char = utf8.byte(str)
	return getCharWidth(char) > 1
end
function env.unicode.charWidth(str)
	cprint("unicode.charWidth", str)
	checkArg(1,str,"string")
	if #str == 0 then
		error("String index out of range: 0", 0)
	end
	local char = utf8.byte(str)
	return getCharWidth(char)
end
function env.unicode.wlen(str)
	cprint("unicode.wlen", str)
	checkArg(1,str,"string")
	local length = 0
	for _,c in utf8.next, str do
		length = length + getCharWidth(c)
	end
	return length
end
function env.unicode.wtrunc(str, count)
	cprint("unicode.wtrunc", str, count)
	checkArg(1,str,"string")
	checkArg(2,count,"number")
	if count == math.huge then
		count = 0
	end
	local width = 0
	local pos = 0
	local len = utf8.len(str)
	while (width < count) do
		pos = pos + 1
		if pos > len then
			error("String index out of range: " .. pos-1, 0)
		end
		width = width + getCharWidth(utf8.byte(str,pos,pos))
	end
	return utf8.sub(str, 1, math.max(pos-1,0))
end
