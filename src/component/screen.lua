local address, slot, maxwidth, maxheight, maxtier = ...

local utf8 = require("utf8")

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

local window, err = elsa.window.createWindow({title="OCEmu - screen@" .. address, width=width*8, height=height*16})
if not window then
	error(err)
end


local render, err = elsa.graphics.createRenderer(window, 0, 0)
if not render then
	error(err)
end

local lastcolor
local function setDrawColor(color)
	if color ~= lastcolor then
		render:setDrawColor(color)
		lastcolor = color
	end
end

setDrawColor(0)
render:clear()

function elsa.draw()
	window:show()
	render:present()
end

local points = {}
local function renderChar(char,x,y,fg,bg)
	if unifont[char] ~= nil then
		char = unifont[char]
		local size = #char/16
		for i = 1,#char,size do
			local line = tonumber(char:sub(i,i+size-1),16)
			local cx = x
			for j = size*4-1,0,-1 do
				local bit = math.floor(line/2^j)%2
				local color = bit == 0 and bg or fg
				if x >= 0 and y >= 0 and x < width * 8 and y < height * 16 then
					if points[color] == nil then
						points[color] = {}
					end
					points[color][#points[color]+1] = {x=cx, y=y}
				end
				cx = cx + 1
			end
			y = y + 1
		end
	end
end

local function drawPoints()
	for color,list in pairs(points) do
		setDrawColor(color)
		render:drawPoints(list)
	end
	points = {}
end

local function setPos(x,y,c,fg,bg)
	local change = screen.txt[y][x] ~= utf8.char(c) or screen.fg[y][x] ~= scrfgc or screen.bg[y][x] ~= scrbgc or screen.fgp[y][x] ~= scrfgp or screen.bgp[y][x] ~= scrbgp
	if change then
		screen.txt[y][x] = utf8.char(c)
		screen.fg[y][x] = scrfgc
		screen.bg[y][x] = scrbgc
		screen.fgp[y][x] = scrfgp
		screen.bgp[y][x] = scrbgp
		renderChar(c,(x-1)*8,(y-1)*16,fg,bg)
	end
end

local touchinvert = false
local precise = false

-- screen component
local obj = {}

function obj.isTouchModeInverted() -- Whether touch mode is inverted (sneak-activate opens GUI, instead of normal activate).
	cprint("screen.isTouchModeInverted")
	return touchinvert
end
function obj.setTouchModeInverted(value) -- Sets whether to invert touch mode (sneak-activate opens GUI, instead of normal activate).
	--STUB
	cprint("screen.setTouchModeInverted", value)
	compCheckArg(1,value,"boolean")
	touchinvert = value
end
function obj.isPrecise() -- Returns whether the screen is in high precision mode (sub-pixel mouse event positions).
	cprint("screen.isPrecise")
	return precise
end
function obj.setPrecise(enabled) -- Set whether to use high precision mode (sub-pixel mouse event positions).
	cprint("screen.setPrecise", enabled)
	compCheckArg(1,enabled,"boolean")
	precise = enabled
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
	cprint("screen.getKeyboards")
	local klist = {}
	for addr in component.list("keyboard",true) do
		klist[#klist+1] = addr
	end
	return klist
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
	local code = utf8.byte(char)
	for y = y1,y2 do
		for x = x1,x2 do
			setPos(x,y,code,scrfgc,scrbgc)
		end
	end
	drawPoints()
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
	if vertical and x >= 1 and x <= width and y <= height then
		for _,c in utf8.next, value do
			if y >= 1 then
				setPos(x,y,c,scrfgc,scrbgc)
			end
			y = y + 1
			if y > height then break end
		end
	elseif not vertical and y >= 1 and y <= height and x <= width then
		for _,c in utf8.next, value do
			if x >= 1 then
				setPos(x,y,c,scrfgc,scrbgc)
			end
			x = x + #unifont[c]/32
			if x > width then break end
		end
	end
	drawPoints()
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
			local change = screen.txt[y][x] ~= copy.txt[y-y1-ty][x-x1-tx] or screen.fg[y][x] ~= copy.fg[y-y1-ty][x-x1-tx] or screen.bg[y][x] ~= copy.bg[y-y1-ty][x-x1-tx] or screen.fgp[y][x] ~= copy.fgp[y-y1-ty][x-x1-tx] or screen.bgp[y][x] ~= copy.bgp[y-y1-ty][x-x1-tx]
			if change then
				screen.txt[y][x] = copy.txt[y-y1-ty][x-x1-tx]
				screen.fg[y][x] = copy.fg[y-y1-ty][x-x1-tx]
				screen.bg[y][x] = copy.bg[y-y1-ty][x-x1-tx]
				screen.fgp[y][x] = copy.fgp[y-y1-ty][x-x1-tx]
				screen.bgp[y][x] = copy.bgp[y-y1-ty][x-x1-tx]
				-- Speedup somehow D:
				renderChar(utf8.byte(copy.txt[y-y1-ty][x-x1-tx]),(x-1)*8,(y-1)*16,copy.fg[y-y1-ty][x-x1-tx],copy.bg[y-y1-ty][x-x1-tx])
			end
		end
	end
	drawPoints()
end

return obj,cec
