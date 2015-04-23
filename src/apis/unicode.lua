local env = ...

local utf8 = require("utf8")

env.unicode = {}

function env.unicode.lower(str)
	-- STUB
	cprint("unicode.lower", str)
	checkArg(1,str,"string")
	return utf8.lower(str)
end
function env.unicode.upper(str)
	-- STUB
	cprint("unicode.upper", str)
	checkArg(1,str,"string")
	return utf8.upper(str)
end
function env.unicode.char(...)
	-- TODO
	cprint("unicode.char", ...)
	return utf8.char(...)
end
function env.unicode.len(str)
	-- TODO
	cprint("unicode.len", str)
	checkArg(1,str,"string")
	return utf8.len(str)
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
	return utf8.len(str)
end
function env.unicode.wtrunc(str, count)
	-- STUB
	cprint("unicode.wtrunc", str, count)
	checkArg(1,str,"string")
	checkArg(2,count,"number")
	local len = utf8.len(str)
	if count >= len then
		error("String index out of range: " .. len,2)
	end
	return utf8.sub(str, 1, count-1)
end
