local address = ...

local ffi = require("ffi")
local lua_utf8 = require("utf8")
local SDL = elsa.SDL

-- Conversion table for SDL2 keys to LWJGL key codes
local keys = require("support.sdl_to_lwjgl")

local code2char = {}

local function setLatest(char)
	kbdcodes[#kbdcodes].char = char
	code2char[kbdcodes[#kbdcodes].code] = char
end

function elsa.textinput(event)
	local textevent = ffi.cast("SDL_TextInputEvent", event)
	local text = ffi.string(textevent.text)
	cprint("textinput",text)
	setLatest(lua_utf8.byte(text))
end

function elsa.keydown(event)
	local keyevent = ffi.cast("SDL_KeyboardEvent", event)
	local key = keyevent.keysym.scancode
	cprint("keydown",keys[key])
	table.insert(kbdcodes,{type="key_down",addr=address,code=keys[key] or 0})
	-- TODO: Lovely SDL Hacks
	if keys[key] == 15 then
		setLatest(9)
	elseif keys[key] == 28 or keys[key] == 156 then
		setLatest(13)
	end
	if keys[key] == 210 then
		if SDL.hasClipboardText() > 0 then
			table.insert(machine.signals,{"clipboard",address,ffi.string(SDL.getClipboardText())})
		end
	end
end

function elsa.keyup(event)
	local keyevent = ffi.cast("SDL_KeyboardEvent", event)
	local key = keyevent.keysym.scancode
	cprint("keydown",keys[key])
	table.insert(kbdcodes,{type="key_up",addr=address,code=keys[key],char=code2char[keys[key]]})
end

-- keyboard component

-- Much complex
local obj = {type="keyboard"}

-- Such methods
local cec = {}

-- Wow
return obj,cec
