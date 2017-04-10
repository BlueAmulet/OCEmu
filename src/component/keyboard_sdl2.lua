local address = ...

local bit = require("bit32")
local ffi = require("ffi")
local utf8 = require("lua-utf8")
local SDL = elsa.SDL

local kbdstate = SDL.getKeyboardState(ffi.NULL)

-- Conversion table for SDL2 keys to LWJGL key codes
local keys,codes,numkeys = elsa.filesystem.load("support/sdl_to_lwjgl.lua")()

local function filterChar(char)
	if char >= 2^30 then -- 2^30 and above are scancodes
		return 0
	end
	-- HACK: Check if Control is pressed and generate control codes
	if kbdstate[SDL.SCANCODE_LCTRL] ~= 0 or kbdstate[SDL.SCANCODE_RCTRL] ~= 0 then
		if char >= 97 and char <= 122 then
			char = char - 96
		elseif char >= 91 and char <= 95 then
			char = char - 64
		elseif char == 64 then
			char = 0
		end
	end
	return char
end

function elsa.keydown(event)
	local keyevent = ffi.cast("SDL_KeyboardEvent*", event)
	local key = tonumber(keyevent.keysym.scancode)
	local char = tonumber(keyevent.keysym.sym)
	local numpad = (bit.band(SDL.getModState(), SDL.KMOD_NUM) ~= 0)
	local lwjgl = numpad and numkeys[key] or keys[key]
	cprint("keydown",key,lwjgl)
	-- TODO: Lovely SDL Hacks
	if lwjgl ~= 1 then -- Escape
		if lwjgl ~= nil and codes[lwjgl] ~= nil then
			char = codes[lwjgl]
		else
			char = filterChar(char)
		end
		table.insert(machine.signals, {"key_down", address, char, lwjgl or 0})
		if lwjgl == 210 then
			if SDL.hasClipboardText() > 0 then
				table.insert(machine.signals,{"clipboard",address,ffi.string(SDL.getClipboardText())})
			end
		end
	end
end

function elsa.keyup(event)
	local keyevent = ffi.cast("SDL_KeyboardEvent*", event)
	local key = tonumber(keyevent.keysym.scancode)
	local char = tonumber(keyevent.keysym.sym)
	local numpad = (bit.band(SDL.getModState(), SDL.KMOD_NUM) ~= 0)
	local lwjgl = numpad and numkeys[key] or keys[key]
	cprint("keyup",key,lwjgl)
	if key ~= 41 then -- Escape
		if lwjgl ~= nil and codes[lwjgl] ~= nil then
			char = codes[lwjgl]
		else
			char = filterChar(char)
		end
		table.insert(machine.signals, {"key_up", address, char, lwjgl or 0})
	end
end

-- keyboard component

-- Much complex
local mai = {}

-- Such methods
local obj = {type="keyboard"}

-- Wow
return obj,nil,mai
