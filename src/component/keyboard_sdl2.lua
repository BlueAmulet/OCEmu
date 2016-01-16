local address = ...

local ffi = require("ffi")
local utf8 = require("lua-utf8")
local SDL = elsa.SDL

-- Conversion table for SDL2 keys to LWJGL key codes
local keys,codes = elsa.filesystem.load("support/sdl_to_lwjgl.lua")()

local code2char = {}

local function setLatest(char)
	kbdcodes[#kbdcodes].char = char
	code2char[kbdcodes[#kbdcodes].code] = char
end

function elsa.textinput(event)
	local textevent = ffi.cast("SDL_TextInputEvent*", event)
	local text = ffi.string(textevent.text)
	cprint("textinput",text)
	setLatest(utf8.byte(text))
end

function elsa.keydown(event)
	local keyevent = ffi.cast("SDL_KeyboardEvent*", event)
	local key = tonumber(keyevent.keysym.scancode)
	local lwjgl = keys[key]
	cprint("keydown",key,lwjgl)
	-- TODO: Lovely SDL Hacks
	if lwjgl ~= 1 then -- Escape
		table.insert(kbdcodes,{type="key_down",addr=address,code=lwjgl or 0})
	end
	if lwjgl ~= nil and codes[lwjgl] ~= nil then
		setLatest(codes[lwjgl])
	end
	if lwjgl == 210 then
		if SDL.hasClipboardText() > 0 then
			table.insert(machine.signals,{"clipboard",address,ffi.string(SDL.getClipboardText())})
		end
	end
end

function elsa.keyup(event)
	local keyevent = ffi.cast("SDL_KeyboardEvent*", event)
	local key = tonumber(keyevent.keysym.scancode)
	local lwjgl = keys[key]
	cprint("keyup",key,lwjgl)
	if key ~= 41 then -- Escape
		table.insert(kbdcodes,{type="key_up",addr=address,code=lwjgl or 0,char=code2char[lwjgl]})
	end
end

-- keyboard component

-- Much complex
local obj = {type="keyboard"}

-- Such methods
local cec = {}

-- Wow
return obj,cec
