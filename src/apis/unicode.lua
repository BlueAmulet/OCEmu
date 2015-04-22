local env = ...

local utf8 = require('utf8_simple')
local lua_utf8 = require("utf8")

function z(val)
	local size = val < 0x10000 and (val < 0x800 and (val < 0x80 and 1 or 2) or 3) or 4
	if size == 1 then return string.char(val) end
	local b = {string.char((240*2^(4-size)%256)+(val/2^(size*6-6))%(2^(7-size)))}
	for i = size*6-12,0,-6 do
		b[#b+1] = string.char(128+(val/2^i)%64)
	end
	return table.concat(b)
end

env.unicode = {}

function env.unicode.lower(str)
	-- STUB
	cprint("unicode.lower", str)
	checkArg(1,str,"string")
	return string.lower(str)
end
function env.unicode.upper(str)
	-- STUB
	cprint("unicode.upper", str)
	checkArg(1,str,"string")
	return string.upper(str)
end
function env.unicode.char(...)
	-- TODO
	cprint("unicode.char", ...)
	--return lua_utf8.char(...) -- Why does this return "%U"
	local output = {}
	local codes = { ... }
	for i = 1,#codes do
		output[i] = z(codes[i])
	end
	return table.concat(output)
end
function env.unicode.len(str)
	-- TODO
	cprint("unicode.len", str)
	checkArg(1,str,"string")
	return lua_utf8.len(str)
end
function env.unicode.reverse(str)
	-- TODO
	cprint("unicode.reverse", str)
	checkArg(1,str,"string")
	return utf8.reverse(str)
end
function env.unicode.sub(str, i, j)
	-- TODO
	cprint("unicode.sub", str, i, j)
	return utf8.sub(str, i, j)
end
function env.unicode.isWide(str)
	-- STUB
	cprint("unicode.isWide", str)
	checkArg(1,str,"string")
	return false
end
function env.unicode.charWidth(str)
	-- STUB
	cprint("unicode.charWidth", str)
	checkArg(1,str,"string")
	return 1
end
function env.unicode.wlen(str)
	-- STUB
	cprint("unicode.wlen", str)
	checkArg(1,str,"string")
	return lua_utf8.len(str)
end
function env.unicode.wtrunc(str, count)
	-- STUB
	cprint("unicode.wtrunc", str, count)
	checkArg(1,str,"string")
	checkArg(2,count,"number")
	local len = lua_utf8.len(str)
	if count >= len then
		error("String index out of range: " .. len,2)
	end
	return utf8.sub(str, 1, count-1)
end
