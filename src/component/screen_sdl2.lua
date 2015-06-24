local address, _, maxwidth, maxheight, maxtier = ...
compCheckArg(1,maxwidth,"number")
compCheckArg(2,maxheight,"number")
compCheckArg(3,maxtier,"number")

local ffi = require("ffi")
local utf8 = require("utf8")
local bit = require("bit32")
local SDL = elsa.SDL

local width, height, tier = maxwidth, maxheight, maxtier
local scrfgc, scrfgp = 0xFFFFFF
local scrbgc, scrfgp = 0x000000
local scrrfc, srcrbc = scrfgc, scrbgc
local palcol = {}

t3pal = {}
for i = 0,15 do
	t3pal[i] = (i+1)*0x0F0F0F
end
local t2pal = {[0]=0xFFFFFF,0xFFCC33,0xCC66CC,0x6699FF,0xFFFF33,0x33CC33,0xFF6699,0x333333,0xCCCCCC,0x336699,0x9933CC,0x333399,0x663300,0x336600,0xFF3333,0x000000}
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
local function loadPalette()
	local palcopy
	if tier == 3 then
		palcopy = t3pal
	else
		palcopy = t2pal
	end
	for i = 0,15 do
		palcol[i] = palcopy[i]
	end
	if scrfgp then
		scrrfc, scrfgc = palcol[scrfgp], palcol[scrfgp]
	end
	if scrbgp then
		scrrbc, scrbgc = palcol[scrbgp], palcol[scrbgp]
	end
end
if tier > 1 then
	loadPalette()
end

local buttons = {[SDL.BUTTON_LEFT] = 0, [SDL.BUTTON_RIGHT] = 1}
local moved, bttndown, lx, ly = false
function elsa.mousebuttondown(event)
	local mbevent = ffi.cast("SDL_MouseButtonEvent", event)
	if buttons[mbevent.button] then
		if not bttndown then
			lx, ly = math.floor(mbevent.x/8)+1,math.floor(mbevent.y/16)+1
			table.insert(machine.signals,{"touch",address,lx,ly,buttons[mbevent.button]})
		end
		bttndown = buttons[mbevent.button]
	end
end

function elsa.mousebuttonup(event)
	local mbevent = ffi.cast("SDL_MouseButtonEvent", event)
	if bttndown and buttons[mbevent.button] then
		if moved then
			moved = false
			table.insert(machine.signals,{"drop",address,lx,ly,buttons[mbevent.button]})
		end
		bttndown = nil
	end
end

function elsa.mousemotion(event)
	local mmevent = ffi.cast("SDL_MouseMotionEvent", event)
	if bttndown then
		local nx, ny = math.floor(mmevent.x/8)+1,math.floor(mmevent.y/16)+1
		if nx ~= lx or ny ~= ly then
			moved = true
			table.insert(machine.signals,{"drag",address,nx,ny,bttndown})
			lx, ly = nx, ny
		end
	end
end

function elsa.mousewheel(event)
	local mwevent = ffi.cast("SDL_MouseWheelEvent", event)
	local x,y = ffi.new("int[1]"),ffi.new("int[1]")
	SDL.getMouseState(ffi.cast("int*",x), ffi.cast("int*",y))
	table.insert(machine.signals,{"scroll",address,math.floor(x[0]/8)+1,math.floor(y[0]/16)+1,mwevent.y})
end

local window = SDL.createWindow("OCEmu - screen@" .. address, SDL.WINDOWPOS_CENTERED, SDL.WINDOWPOS_CENTERED, width*8, height*16, SDL.WINDOW_SHOWN)
if window == ffi.C.NULL then
	error(ffi.string(SDL.getError()))
end
local flags = SDL.RENDERER_TARGETTEXTURE
if ffi.os == "Windows" then -- TODO: Investigate why
	flags = flags + SDL.RENDERER_SOFTWARE
end
local renderer = SDL.createRenderer(window, -1, flags)
if renderer == ffi.C.NULL then
	error(ffi.string(SDL.getError()))
end
local texture = SDL.createTexture(renderer, SDL.PIXELFORMAT_ARGB8888, SDL.TEXTUREACCESS_TARGET, width*8, height*16);
if texture == ffi.C.NULL then
	error(ffi.string(SDL.getError()))
end
local copytexture = SDL.createTexture(renderer, SDL.PIXELFORMAT_ARGB8888, SDL.TEXTUREACCESS_TARGET, width*8, height*16);
if copytexture == ffi.C.NULL then
	error(ffi.string(SDL.getError()))
end

-- Initialize all the textures to black
SDL.setRenderDrawColor(renderer, 0, 0, 0, 255)
SDL.renderFillRect(renderer, ffi.C.NULL)
SDL.setRenderTarget(renderer, texture);
SDL.renderFillRect(renderer, ffi.C.NULL)
SDL.setRenderTarget(renderer, copytexture);
SDL.renderFillRect(renderer, ffi.C.NULL)
SDL.setRenderTarget(renderer, ffi.C.NULL);

function elsa.draw()
	SDL.renderCopy(renderer, texture, ffi.C.NULL, ffi.C.NULL)
	SDL.renderPresent(renderer)
end

local char8 = ffi.new("uint32_t[?]", 8*16)
local char16 = ffi.new("uint32_t[?]", 16*16)
local function renderChar(char,x,y,fg,bg)
	if unifont[char] == nil then
		char = 63
	end
	char = unifont[char]
	local size,pchar = #char/16
	if size == 2 then
		pchar = char8
	else
		pchar = char16
	end
	local cy = 0
	for i = 1,#char,size do
		local line = tonumber(char:sub(i,i+size-1),16)
		local cx = 0
		for j = size*4-1,0,-1 do
			local bit = math.floor(line/2^j)%2
			local color = bit == 0 and bg or fg
			pchar[cy*size*4+cx] = color + 0xFF000000
			cx = cx + 1
		end
		cy = cy + 1
	end
	SDL.updateTexture(texture, ffi.new("SDL_Rect",{x=x,y=y,w=size*4,h=16}), pchar, (size*4) * ffi.sizeof("uint32_t"))
end

local function screenSet(x,y,c)
	screen.txt[y][x] = utf8.char(c)
	screen.fg[y][x] = scrfgc
	screen.bg[y][x] = scrbgc
	screen.fgp[y][x] = scrfgp
	screen.bgp[y][x] = scrbgp
end

local function setPos(x,y,c,fg,bg)
	local renderchange = screen.txt[y][x] ~= utf8.char(c) or screen.bg[y][x] ~= scrbgc or (screen.txt[y][x] ~= " " and screen.fg[y][x] ~= scrfgc)
	local charWidth = getCharWidth(c)
	if charWidth == 1 or x < width then
		local renderafter = getCharWidth(utf8.byte(screen.txt[y][x])) > 1 and charWidth == 1 and x < width
		if x > 1 and getCharWidth(utf8.byte(screen.txt[y][x-1])) > 1 then
			renderchange = false
		else
			screenSet(x,y,c)
		end
		if renderchange then
			renderChar(c,(x-1)*8,(y-1)*16,fg,bg)
			if charWidth > 1 then
				screenSet(x+1,y,32)
			end
		end
		if renderafter then
			renderChar(32,x*8,(y-1)*16,screen.fg[y][x+1],screen.bg[y][x+1])
		end
	end
end

local function extract(value)
	return bit.rshift(bit.band(value,0xFF0000),16),
		bit.rshift(bit.band(value,0xFF00),8),
		bit.band(value,0xFF)
end

local function compare(value1, value2)
	local r1,g1,b1 = extract(value1)
	local r2,g2,b2 = extract(value2)
	local dr,dg,db = r1-r2,g1-g2,b1-b2
	return 0.2126*dr^2 + 0.7152*dg^2 + 0.0722*db^2
end

local function searchPalette(value)
	local score, index = math.huge
	for i = 0,15 do
		local tscore = compare(value,palcol[i])
		if score > tscore then
			score = tscore
			index = i
		end
	end
	return index, score
end

local function getColor(value, sel)
	if sel then
		scrfgp = nil
	else
		scrbgp = nil
	end
	if tier == 3 then
		local pi,ps = searchPalette(value)
		local r,g,b = extract(value)
		r=math.floor(math.floor(r*5/255+0.5)*255/5+0.5)
		g=math.floor(math.floor(g*7/255+0.5)*255/7+0.5)
		b=math.floor(math.floor(b*4/255+0.5)*255/4+0.5)
		local defc = r*65536 + g*256 + b
		local defs = compare(value, defc)
		if defs < ps then
			return defc
		else
			if sel then
				scrfgp = pi
			else
				scrbgp = pi
			end
			return palcol[pi]
		end
	elseif tier == 2 then
		local pi = searchPalette(value)
		if sel then
			scrfgp = pi
		else
			scrbgp = pi
		end
		return palcol[pi]
	else
		if value > 0 then
			return 0xFFFFFF -- TODO: Configuration color
		else
			return 0
		end
	end
end

local touchinvert = false
local precise = false

-- screen component
local obj = {type="screen"}

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
	return scrrfc, scrfgp
end
function cec.setForeground(value, palette) -- Sets the foreground color to the specified value. Optionally takes an explicit palette index. Returns the old value and if it was from the palette its palette index.
	cprint("(cec) screen.setForeground", value, palette)
	local oldc, oldp = scrrfc, scrfgp
	scrrfc = palette and palcol[value] or value
	scrfgp = palette and value
	scrfgc = palette and scrrfc or getColor(scrrfc,true)
	return oldc, oldp
end
function cec.getBackground() -- Get the current background color and whether it's from the palette or not.
	cprint("(cec) screen.getBackground")
	return scrrbc, scrbgp
end
function cec.setBackground(value, palette) -- Sets the background color to the specified value. Optionally takes an explicit palette index. Returns the old value and if it was from the palette its palette index.
	cprint("(cec) screen.setBackground", value, palette)
	local oldc, oldp = scrrbc, scrbgp
	scrrbc = palette and palcol[value] or value
	scrbgp = palette and value
	scrbgc = palette and scrrbc or getColor(scrrbc,false)
	return oldc, oldp
end
function cec.getDepth() -- Returns the currently set color depth.
	cprint("(cec) screen.getDepth")
	return tier
end
function cec.setDepth(depth) -- Set the color depth. Returns the previous value.
	cprint("(cec) screen.setDepth", depth)
	tier = math.min(depth, maxtier)
	if tier > 1 then
		loadPalette()
	end
	scrfgc = getColor(scrrfc,true)
	scrfbc = getColor(scrrbc,false)
	-- TODO: Lowering the depth recolors the entire screen
end
function cec.maxDepth() -- Get the maximum supported color depth.
	cprint("(cec) screen.maxDepth")
	return maxtier
end
function cec.fill(x1, y1, w, h, char) -- Fills a portion of the screen at the specified position with the specified size with the specified character.
	--TODO
	cprint("(cec) screen.fill", x1, y1, w, h, char)
	x1,y1,w,h=math.trunc(x1),math.trunc(y1),math.trunc(w),math.trunc(h)
	if w <= 0 or h <= 0 then
		return true
	end
	local code = utf8.byte(char)
	local x2 = x1+(w*getCharWidth(code))-1
	local y2 = y1+h-1
	if x2 < 1 or y2 < 1 or x1 > width or y1 > height then
		return true
	end
	for y = y1,y2 do
		for x = x1,x2,getCharWidth(code) do
			setPos(x,y,code,scrfgc,scrbgc)
		end
	end
	return true
end
function cec.getResolution() -- Get the current screen resolution.
	cprint("(cec) screen.getResolution")
	return width, height
end
function cec.setResolution(newwidth, newheight) -- Set the screen resolution. Returns true if the resolution changed.
	cprint("(cec) screen.setResolution", newwidth, newheight)
	newwidth,newheight = math.floor(newwidth),math.floor(newheight)
	local oldwidth, oldheight = width, height
	width, height = newwidth, newheight
	return oldwidth ~= width or oldheight ~= height
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
	cprint("(cec) screen.setPaletteColor", index, color)
	local old = palcol[index]
	palcol[index] = color
	if scrfgp == index then
		scrrfc, scrfgc = color, color
	end
	if scrbgp == index then
		scrrbc, scrbgc = color, color
	end
	-- TODO: Palette changes recolor the screen for respective characters
	return old
end
function cec.get(x, y) -- Get the value displayed on the screen at the specified index, as well as the foreground and background color. If the foreground or background is from the palette, returns the palette indices as fourth and fifth results, else nil, respectively.
	cprint("(cec) screen.get", x, y)
	x,y=math.trunc(x),math.trunc(y)
	return screen.txt[y][x], screen.fg[y][x], screen.bg[y][x], screen.fgp[y][x], screen.bgp[y][x]
end
function cec.set(x, y, value, vertical) -- Plots a string value to the screen at the specified position. Optionally writes the string vertically.
	-- TODO: Offscreen Y set is weird in OC.
	cprint("(cec) screen.set", x, y, value, vertical)
	x,y=math.trunc(x),math.trunc(y)
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
			x = x + getCharWidth(c)
			if x > width then break end
		end
	end
	return true
end
function cec.copy(x1, y1, w, h, tx, ty) -- Copies a portion of the screen from the specified location with the specified size by the specified translation.
	--TODO
	cprint("(cec) screen.copy", x1, y1, w, h, tx, ty)
	-- TODO: copy has issues with wide characters
	x1,y1,w,h,tx,ty=math.trunc(x1),math.trunc(y1),math.trunc(w),math.trunc(h),math.trunc(tx),math.trunc(ty)
	if w <= 0 or h <= 0 or (tx == 0 and ty == 0) then
		return true
	end
	local x2 = x1+w-1
	local y2 = y1+h-1
	-- TODO: Not dealing with offscreen stuff yet
	if x1 < 1 or y1 < 1 or x2 > width or y2 > height then
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
	local my1,my2 = math.max(math.min(y1+ty, height), 1), math.max(math.min(y2+ty, height), 1)
	local mx1,mx2 = math.max(math.min(x1+tx, width), 1), math.max(math.min(x2+tx, width), 1)
	for y = my1,my2 do
		for x = mx1,mx2 do
			screen.txt[y][x] = copy.txt[y-y1-ty][x-x1-tx]
			screen.fg[y][x] = copy.fg[y-y1-ty][x-x1-tx]
			screen.bg[y][x] = copy.bg[y-y1-ty][x-x1-tx]
			screen.fgp[y][x] = copy.fgp[y-y1-ty][x-x1-tx]
			screen.bgp[y][x] = copy.bgp[y-y1-ty][x-x1-tx]
		end
	end
	SDL.setRenderTarget(renderer, copytexture);
	SDL.renderCopy(renderer, texture, ffi.C.NULL, ffi.C.NULL)
	SDL.renderCopy(renderer, texture, ffi.new("SDL_Rect",{x=(x1-1)*8,y=(y1-1)*16,w=w*8,h=h*16}), ffi.new("SDL_Rect",{x=(x1+tx-1)*8,y=(y1+ty-1)*16,w=w*8,h=h*16}))
	SDL.setRenderTarget(renderer, ffi.C.NULL);
	texture,copytexture=copytexture,texture
end

local doc = {
	["isTouchModeInverted"]="function():boolean -- Whether touch mode is inverted (sneak-activate opens GUI, instead of normal activate).",
	["setTouchModeInverted"]="function(value:boolean):boolean -- Sets whether to invert touch mode (sneak-activate opens GUI, instead of normal activate).",
	["isPrecise"]="function():boolean -- Returns whether the screen is in high precision mode (sub-pixel mouse event positions).",
	["setPrecise"]="function(enabled:boolean):boolean -- Set whether to use high precision mode (sub-pixel mouse event positions).",
	["turnOff"]="function():boolean -- Turns off the screen. Returns true if it was on.",
	["turnOn"]="function():boolean -- Turns the screen on. Returns true if it was off.",
	["isOn"]="function():boolean -- Returns whether the screen is currently on.",
	["getAspectRatio"]="function():number, number -- The aspect ratio of the screen. For multi-block screens this is the number of blocks, horizontal and vertical.",
	["getKeyboards"]="function():table -- The list of keyboards attached to the screen.",
}

return obj,cec,doc
