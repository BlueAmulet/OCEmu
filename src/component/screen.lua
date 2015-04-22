local address, slot, maxwidth, maxheight, maxtier = ...

local lua_utf8 = require("utf8")

local width, height, tier = maxwidth, maxheight, maxtier
local scrfgc, scrfgp = 0xFFFFFF
local scrbgc, scrfgp = 0x000000
local palcol
if tier == 3 then
	palcol = {}
	for i = 0,15 do
		palcol[i] = i * 0x111111
	end
else
	palcol = {[0]=0xFFFFFF,0xFFCC33,0xCC66CC,0x6699FF,0xFFFF33,0x33CC33,0xFF6699,0x333333,0xCCCCCC,0x336699,0x9933CC,0x333399,0x663300,0x336600,0xFF3333,0x000000}
end
local screen = {txt = {}, fg = {}, bg = {}, fgp = {}, bgp = {}}
for y = 1,height do
	screen.txt[y] = {}
	screen.fg[y] = {}
	screen.bg[y] = {}
	screen.fgp[y] = {}
	screen.bgp[y] = {}
	for x = 1,width do
		screen.txt[y][x] = " "
		screen.fg[y][x] = scrfgc
		screen.bg[y][x] = scrbgc
		screen.fgp[y][x] = scrfgp
		screen.bgp[y][x] = scrbgp
	end
end

function z(val)
	local size = val < 0x10000 and (val < 0x800 and (val < 0x80 and 1 or 2) or 3) or 4
	if size == 1 then return string.char(val) end
	local b = {string.char((240*2^(4-size)%256)+(val/2^(size*6-6))%(2^(7-size)))}
	for i = size*6-12,0,-6 do
		b[#b+1] = string.char(128+(val/2^i)%64)
	end
	return table.concat(b)
end

love.window.setMode(width*8, height*16,{})

local idata = love.image.newImageData(width*8, height*16)
idata:mapPixel(function() return 0,0,0,255 end)
local image = love.graphics.newImage(idata)

function love.draw()
	love.graphics.draw(image)
end

local function breakColor(color)
	return math.floor(color/65536%256), math.floor(color/256%256), math.floor(color%256)
end

local function renderChar(char,x,y,fr,fg,fb,br,bg,bb)
	if unifont[char] ~= nil then
		char = unifont[char]
		local size = #char/16
		for i = 1,#char,size do
			local line = tonumber(char:sub(i,i+size-1),16)
			local cx = x
			for j = size*4-1,0,-1 do
				local bit = math.floor(line/2^j)%2
				if bit == 0 then
					idata:setPixel(cx,y,br,bg,bb,255)
				else
					idata:setPixel(cx,y,fr,fg,fb,255)
				end
				cx = cx + 1
			end
			y = y + 1
		end
	end
end

local function setPos(x,y,c,fr,fg,fb,br,bg,bb)
	screen.txt[y][x] = z(c)
	screen.fg[y][x] = scrfgc
	screen.bg[y][x] = scrbgc
	screen.fgp[y][x] = scrfgp
	screen.bgp[y][x] = scrbgp
	renderChar(c,(x-1)*8,(y-1)*16,fr,fg,fb,br,bg,bb)
end

-- screen component
local obj = {}

function obj.isTouchModeInverted() -- Whether touch mode is inverted (sneak-activate opens GUI, instead of normal activate).
	--STUB
	cprint("screen.isTouchModeInverted")
	return false
end
function obj.setTouchModeInverted(value) -- Sets whether to invert touch mode (sneak-activate opens GUI, instead of normal activate).
	--STUB
	cprint("screen.setTouchModeInverted", value)
end
function obj.isPrecise() -- Returns whether the screen is in high precision mode (sub-pixel mouse event positions).
	--STUB
	cprint("screen.isPrecise")
	return false
end
function obj.setPrecise(enabled) -- Set whether to use high precision mode (sub-pixel mouse event positions).
	--STUB
	cprint("screen.setPrecise", enabled)
end
function obj.turnOff() -- Turns off the screen. Returns true if it was on.
	--STUB
	cprint("screen.turnOff")
	return false
end
function obj.turnOn() -- Turns the screen on. Returns true if it was off.
	--STUB
	cprint("screen.turnOn")
	return false
end
function obj.isOn() -- Returns whether the screen is currently on.
	--STUB
	cprint("screen.isOn")
	return true
end
function obj.getAspectRatio() -- The aspect ratio of the screen. For multi-block screens this is the number of blocks, horizontal and vertical.
	--STUB
	cprint("screen.getAspectRatio")
	return 1, 1
end
function obj.getKeyboards() -- The list of keyboards attached to the screen.
	--STUB
	cprint("screen.getKeyboards")
	return {}
end

local cec = {}

function cec.getForeground() -- Get the current foreground color and whether it's from the palette or not.
	cprint("(cec) screen.getForeground")
	return scrfgc, nil
end
function cec.setForeground(value, palette) -- Sets the foreground color to the specified value. Optionally takes an explicit palette index. Returns the old value and if it was from the palette its palette index.
	cprint("(cec) screen.setForeground", value, palette)
	local old = scrfgc
	scrfgc = palette and palcol[value] or value
	scrfgp = palette and value
	return old, nil
end
function cec.getBackground() -- Get the current background color and whether it's from the palette or not.
	cprint("(cec) screen.getBackground")
	return scrbgc, nil
end
function cec.setBackground(value, palette) -- Sets the background color to the specified value. Optionally takes an explicit palette index. Returns the old value and if it was from the palette its palette index.
	cprint("(cec) screen.setBackground", value, palette)
	local old = scrbgc
	scrbgc = palette and palcol[value] or value
	scrbgp = palette and value
	return old, nil
end
function cec.getDepth() -- Returns the currently set color depth.
	cprint("(cec) screen.getDepth")
	return tier
end
function cec.setDepth(depth) -- Set the color depth. Returns the previous value.
	cprint("(cec) screen.setDepth", depth)
	tier = math.min(depth, maxtier)
end
function cec.maxDepth() -- Get the maximum supported color depth.
	cprint("(cec) screen.maxDepth")
	return maxtier
end
function cec.fill(x1, y1, w, h, char) -- Fills a portion of the screen at the specified position with the specified size with the specified character.
	--STUB
	cprint("(cec) screen.fill", x1, y1, w, h, char)
	if w <= 0 or h <= 0 then
		return true
	end
	local x2 = x1+w-1
	local y2 = y1+h-1
	if x2 < 1 or y2 < 1 or x1 > width or y1 > height then
		return true
	end
	local fr,fg,fb = breakColor(scrfgc)
	local br,bg,bb = breakColor(scrbgc)
	local code = lua_utf8.codepoint(char)
	for y = y1,y2 do
		for x = x1,x2 do
			setPos(x,y,code,fr,fg,fb,br,bg,bb)
		end
	end
end
function cec.getResolution() -- Get the current screen resolution.
	cprint("(cec) screen.getResolution")
	return width, height
end
function cec.setResolution(newwidth, newheight) -- Set the screen resolution. Returns true if the resolution changed.
	cprint("(cec) screen.setResolution", newwidth, newheight)
	width, height = math.min(newwidth, maxwidth), math.min(newheight, maxheight)
end
function cec.maxResolution() -- Get the maximum screen resolution.
	cprint("(cec) screen.maxResolution")
	return maxwidth, maxheight
end
function cec.getPaletteColor(index) -- Get the palette color at the specified palette index.
	cprint("(cec) screen.getPaletteColor", index)
	return palcol[index]
end
function cec.setPaletteColor(index, color) -- Set the palette color at the specified palette index. Returns the previous value.
	--TODO
	cprint("(cec) screen.setPaletteColor", index, color)
	palcol[index] = color
end
function cec.get(x, y) -- Get the value displayed on the screen at the specified index, as well as the foreground and background color. If the foreground or background is from the palette, returns the palette indices as fourth and fifth results, else nil, respectively.
	cprint("(cec) screen.get", x, y)
	return screen.txt[y][x], screen.fg[y][x], screen.bg[y][x], screen.fgp[y][x], screen.bgp[y][x]
end
function cec.set(x, y, value, vertical) -- Plots a string value to the screen at the specified position. Optionally writes the string vertically.
	cprint("(cec) screen.set", x, y, value, vertical)
	local fr,fg,fb = breakColor(scrfgc)
	local br,bg,bb = breakColor(scrbgc)
	if vertical and x >= 1 and x <= width and y <= height then
		for _,c in lua_utf8.codes(value) do
			if y >= 1 then
				setPos(x,y,c,fr,fg,fb,br,bg,bb)
			end
			y = y + 1
			if y > height then break end
		end
		image:refresh()
	elseif not vertical and y >= 1 and y <= height and x <= width then
		for _,c in lua_utf8.codes(value) do
			if x >= 1 then
				setPos(x,y,c,fr,fg,fb,br,bg,bb)
			end
			x = x + #unifont[c]/32
			if x > width then break end
		end
		image:refresh()
	end
	return true
end
function cec.copy(x1, y1, w, h, tx, ty) -- Copies a portion of the screen from the specified location with the specified size by the specified translation.
	--TODO
	cprint("(cec) screen.copy", x1, y1, w, h, tx, ty)
	if w <= 0 or h <= 0 then
		return true
	end
	local x2 = x1+w-1
	local y2 = y1+h-1
	-- Not dealing with offscreen stuff yet
	if x1 < 1 or y1 < 1 or x2 > width or y2 > height or (tx == 0 and ty == 0) then
		return true
	end
	local copy = {txt={},fg={},bg={},fgp={},bgp={}}
	for y = y1,y2 do
		copy.txt[y-y1] = {}
		copy.fg[y-y1] = {}
		copy.bg[y-y1] = {}
		copy.fgp[y-y1] = {}
		copy.bgp[y-y1] = {}
		for x = x1,x2 do
			copy.txt[y-y1][x-x1] = screen.txt[y][x]
			copy.fg[y-y1][x-x1] = screen.fg[y][x]
			copy.bg[y-y1][x-x1] = screen.bg[y][x]
			copy.fgp[y-y1][x-x1] = screen.fgp[y][x]
			copy.bgp[y-y1][x-x1] = screen.bgp[y][x]
		end
	end
	for y = math.max(math.min(y1+ty, height), 1), math.max(math.min(y2+ty, height), 1) do
		for x = math.max(math.min(x1+tx, width), 1), math.max(math.min(x2+tx, width), 1) do
			screen.txt[y][x] = copy.txt[y-y1-ty][x-x1-tx]
			screen.fg[y][x] = copy.fg[y-y1-ty][x-x1-tx]
			screen.bg[y][x] = copy.bg[y-y1-ty][x-x1-tx]
			screen.fgp[y][x] = copy.fgp[y-y1-ty][x-x1-tx]
			screen.bgp[y][x] = copy.bgp[y-y1-ty][x-x1-tx]
			local fr,fg,fb = breakColor(copy.fg[y-y1-ty][x-x1-tx])
			local br,bg,bb = breakColor(copy.bg[y-y1-ty][x-x1-tx])
			-- TODO: Replace with pixel copy, this is slow.
			renderChar(lua_utf8.codepoint(copy.txt[y-y1-ty][x-x1-tx]),(x-1)*8,(y-1)*16,fr,fg,fb,br,bg,bb)
		end
	end
	image:refresh()
end

return obj,cec
