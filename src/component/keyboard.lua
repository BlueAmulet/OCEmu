local address = ...

local lua_utf8 = require("utf8")

-- Conversion table for SDL2 keys to LWJGL key codes
local keys = elsa.filesystem.load("sdl_to_lwjgl.lua")()

local code2char = {}

function elsa.textinput(event)
	local text = event.text
	cprint("textinput",text)
	kbdcodes[#kbdcodes].char = lua_utf8.byte(text)
	code2char[kbdcodes[#kbdcodes].code] = kbdcodes[#kbdcodes].char
end

function elsa.keydown(event)
	local key = event.keysym.scancode
	cprint("keydown",keys[key])
	table.insert(kbdcodes,{type="key_down",addr=address,code=keys[key]})
end

function elsa.keyup(event)
	local key = event.keysym.scancode
	cprint("keydown",keys[key])
	table.insert(kbdcodes,{type="key_up",addr=address,code=keys[key],char=code2char[keys[key]]})
end

-- keyboard component

-- Much complex
local obj = {}

-- Such methods
local cec = {}

-- Wow
return obj,cec
