local env = ...

local utf8 = require("utf8")

env.unicode = {
	lower = utf8.lower,
	upper = utf8.upper,
	char = utf8.char,
	len = utf8.len,
	reverse = utf8.reverse,
	sub = utf8.sub,
}

function env.unicode.isWide(str)
	cprint("unicode.isWide", str)
	checkArg(1,str,"string")
	if #str == 0 then
		error("String index out of range: 0",3)
	end
	local char = utf8.byte(str)
	if unifont[char] ~= nil then
		return #unifont[char] > 32
	end
	return false
end
function env.unicode.charWidth(str)
	cprint("unicode.charWidth", str)
	checkArg(1,str,"string")
	if #str == 0 then
		error("String index out of range: 0",3)
	end
	local char = utf8.byte(str)
	if unifont[char] ~= nil then
		return #unifont[char] / 32
	end
	return 1
end
function env.unicode.wlen(str)
	cprint("unicode.wlen", str)
	checkArg(1,str,"string")
	local length = 0
	for _,c in utf8.next, str do
		if unifont[c] ~= nil then
			length = length + #unifont[c] / 32
		else
			length = length + 1
		end
	end
	return length
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
