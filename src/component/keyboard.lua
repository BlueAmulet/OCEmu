local address = ...

local lua_utf8 = require("utf8")

-- Conversion table for Love2D keys to LWJGL key codes
local keys = {
	["q"] = 16, ["w"] = 17, ["e"] = 18, ["r"] = 19,
	["t"] = 20, ["y"] = 21, ["u"] = 22, ["i"] = 23,
	["o"] = 24, ["p"] = 25, ["a"] = 30, ["s"] = 31,
	["d"] = 32, ["f"] = 33, ["g"] = 34, ["h"] = 35,
	["j"] = 36, ["k"] = 37, ["l"] = 38, ["z"] = 44,
	["x"] = 45, ["c"] = 46, ["v"] = 47, ["b"] = 48,
	["n"] = 49, ["m"] = 50,
	["1"] = 2, ["2"] = 3, ["3"] = 4, ["4"] = 5, ["5"] = 6,
	["6"] = 7, ["7"] = 8, ["8"] = 9, ["9"] = 10, ["0"] = 11,
	[" "] = 57,

	["'"] = 40, [","] = 51, ["-"] = 12, ["."] = 52, ["/"] = 53,
	[":"] = 146, [";"] = 39, ["="] = 13, ["@"] = 145, ["["] = 26,
	["\\"] = 43, ["]"] = 27, ["^"] = 144, ["_"] = 147, ["`"] = 41,

	["up"] = 200,
	["down"] = 208,
	["right"] = 205,
	["left"] = 203,
	["home"] = 199,
	["end"] = 207,
	["pageup"] = 201,
	["pagedown"] = 209,
	["insert"] = 210,
	["backspace"] = 14,
	["tab"] = 15,
	["return"] = 28,
	["delete"] = 211,
	["capslock"] = 58,
	["numlock"] = 69,
	["scrolllock"] = 70,
	
	["f1"] = 59,
	["f2"] = 60,
	["f3"] = 61,
	["f4"] = 62,
	["f5"] = 63,
	["f6"] = 64,
	["f7"] = 65,
	["f8"] = 66,
	["f9"] = 67,
	["f10"] = 68,
	["f12"] = 88,
	["f13"] = 100,
	["f14"] = 101,
	["f15"] = 102,
	["f16"] = 103,
	["f17"] = 104,
	["f18"] = 105,

	["rshift"] = 54,
	["lshift"] = 42,
	["rctrl"] = 157,
	["lctrl"] = 29,
	["ralt"] = 184,
	["lalt"] = 56,
}

local code2char = {}

function love.textinput(t)
	cprint("textinput",t)
	kbdcodes[#kbdcodes].char = lua_utf8.codepoint(t)
	code2char[kbdcodes[#kbdcodes].code] = kbdcodes[#kbdcodes].char
end

function love.keypressed(key)
	cprint("keypressed",key)
	table.insert(kbdcodes,{type="key_down",addr=address,code=keys[key]})
end

function love.keyreleased(key)
	cprint("keyreleased",key)
	table.insert(kbdcodes,{type="key_up",addr=address,code=keys[key],char=code2char[keys[key]]})
end

-- keyboard component

-- Much complex
local obj = {}

-- Such methods
local cec = {}

-- Wow
return obj,cec
