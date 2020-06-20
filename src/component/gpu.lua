local address, _, maxwidth, maxheight, maxtier = ...
compCheckArg(1,maxwidth,"number")
compCheckArg(2,maxheight,"number")
compCheckArg(3,maxtier,"number")

local utf8 = require("lua-utf8")

local bindaddress
local depthTbl = {1,4,8}
local rdepthTbl = {1,[4]=2,[8]=3}
local depthNames = {"OneBit","FourBit","EightBit"}

local setBackgroundCosts = {1/32, 1/64, 1/128}
local setForegroundCosts = {1/32, 1/64, 1/128}
local setPaletteColorCosts = {1/2, 1/8, 1/16}
local setCosts = {1/64, 1/128, 1/256}
local copyCosts = {1/16, 1/32, 1/64}
local fillCosts = {1/32, 1/64, 1/128}
local bitbltCost = 0.5 * math.pow(2, maxtier)

-- gpu component
local mai = {}
local obj = {}

local activeBufferIdx = 0 -- 0 = screen
local buffers = {}
local totalMemory = maxwidth*maxheight*maxtier
local usedMemory = 0

local function bufferSet(buf, x, y, char, fg, bg)
	if x > buf.width or y > buf.height or x < 1 or y < 1 then
		return false
	end
	local pos = (y-1) * buf.width + x
	fg = fg or buf.fg
	bg = bg or buf.bg
	buf.foreground[pos] = fg
	buf.background[pos] = bg
	local before = utf8.sub(buf.text, 1, pos-1)
	local after = utf8.sub(buf.text, pos+1)
	buf.text = before .. char .. after
	buf.dirty = true
	return true
end

local function bufferGet(buf, x, y)
	local pos = (y-1) * buf.width + x
	local char = utf8.sub(buf.text, pos, pos)
	local fg = buf.foreground[pos] or 0xFFFFFF
	local bg = buf.background[pos] or 0
	return char, fg, bg
end

local function consumeGraphicCallBudget(cost)
	if activeBufferIdx == 0 then
		return machine.consumeCallBudget(cost)
	else
		return true
	end
end

mai.allocateBuffer = {direct = true, doc = "function([width: number, height: number]): number -- allocates a new buffer with dimensions width*height (defaults to max resolution) and appends it to the buffer list. Returns the index of the new buffer and returns nil with an error message on failure. A buffer can be allocated even when there is no screen bound to this gpu. Index 0 is always reserved for the screen and thus the lowest index of an allocated buffer is always 1."}
function obj.allocateBuffer(width, height)
	cprint("gpu.allocateBuffer", width, height)
	width = width or maxwidth
	height = height or maxheight

	if width <= 0 or height <= 0 then
		return false, "invalid page dimensions: must be greater than zero"
	end

	local size = width*height
	if usedMemory+size > totalMemory then
		return false, "not enough video memory"
	end
	local buffer = {
		text = (" "):rep(width*height),
		foreground = {},
		background = {},
		width = width,
		height = height,
		size = width*height,
		dirty = true,
		fg = 0xFFFFFF,
		bg = 0x000000,
		bufferGet = bufferGet -- exposure of API for screen_sdl2
	}
	usedMemory = usedMemory + size
	table.insert(buffers, buffer)
	return #buffers
end

mai.freeBuffer = {direct = true, doc = "function(index: number): boolean -- Closes buffer at `index`. Returns true if a buffer closed. If the current buffer is closed, index moves to 0"}
function obj.freeBuffer(idx)
	cprint("gpu.freeBuffer", idx)
	if not buffers[idx] then
		return false, "no buffer at index"
	else
		usedMemory = usedMemory - buffers[idx].size
		buffers[idx] = nil
		if idx == activeBufferIdx then
			idx = 0
		end
		return true
	end
end

mai.freeAllBuffers = {direct = true, doc = "function(): number -- Closes all buffers and returns the count. If the active buffer is closed, index moves to 0"}
function obj.freeAllBuffers()
	local count = #buffers
	activeBufferIdx = 0
	buffers = {}
	usedMemory = 0
	return count
end

mai.buffers = {direct = true, doc = "function(): number -- Returns an array of indexes of the allocated buffers"}
function obj.buffers()
	local array = {}
	for k, v in pairs(buffers) do
		table.insert(array, k)
	end
	return array
end

mai.getActiveBuffer = {direct = true, doc = "function(): number -- returns the index of the currently selected buffer. 0 is reserved for the screen. Can return 0 even when there is no screen"}
function obj.getActiveBuffer()
	return activeBufferIdx
end

mai.setActiveBuffer = {direct = true, doc = "function(index: number): number -- Sets the active buffer to `index`. 1 is the first vram buffer and 0 is reserved for the screen. returns nil for invalid index (0 is always valid)"}
function obj.setActiveBuffer(idx)
	cprint("gpu.setActiveBuffer", idx)
	if idx ~= 0 and not buffers[idx] then
		return nil
	else
		activeBufferIdx = idx
	end
end

mai.freeMemory = {direct = true, doc = "function(): number -- returns the total free memory not allocated to buffers. This does not include the screen."}
function obj.freeMemory()
	return totalMemory - usedMemory
end

mai.totalMemory = {direct = true, doc = "function(): number -- returns the total memory size of the gpu vram. This does not include the screen."}
function obj.totalMemory()
	return totalMemory
end

mai.getBufferSize = {direct = true, doc = "function(index: number): number, number -- returns the buffer size at index. Returns the screen resolution for index 0. returns nil for invalid indexes"}
function obj.getBufferSize(idx)
	if idx == 0 then
		return obj.getResolution()
	else
		local buf = buffers[idx]
		if buf then
			return buf.width, buf.height
		else
			return nil
		end
	end
end

local function determineBitbltBudgetCost(src, dst)
	if dst ~= "screen" then -- write to buffer from buffer/screen are free
		return 0
	elseif src == "screen" then
		return 0
	elseif src.dirty then
		return bitbltCost * (src.width * src.height) / (maxwidth * maxheight)
	elseif not src.dirty then
		return 0.001
	end
end

mai.bitblt = {direct = true, doc = "function([dst: number, col: number, row: number, width: number, height: number, src: number, fromCol: number, fromRow: number]):boolean -- bitblt from buffer to screen. All parameters are optional. Writes to `dst` page in rectangle `x, y, width, height`, defaults to the bound screen and its viewport. Reads data from `src` page at `fx, fy`, default is the active page from position 1, 1"}
function obj.bitblt(dst, col, row, width, height, src, fromCol, fromRow)
	cprint("gpu.bitblt", dst, col, row, width, height, src, fromCol, fromRow)
	dst = dst or 0
	col = col or 1
	row = row or 1
	src = src or activeBufferIdx
	fromCol = fromCol or 1
	fromRow = fromRow or 1

	if dst == 0 then
		if bindaddress == nil then
			return nil, "no screen"
		end
		if not width or not height then
			local rw, rh = component.cecinvoke(bindaddress, "getResolution")
			width = width or rw
			height = height or rh
		end

		-- TODO consume call budget
		if src == 0 then
			-- TODO act as copy()
		else
			local buf = buffers[src]
			if not buf then
				return nil
			end
			local cost = determineBitbltBudgetCost(buf, "screen")
			if not machine.consumeCallBudget(cost) then return end
			buf.dirty = false
			width, height = math.min(buf.width, width), math.min(buf.height, height)
			component.cecinvoke(bindaddress, "bitblt", buf, col, row, width, height, fromCol, fromRow)
		end
	else

	end
end

mai.bind = {doc = "function(address:string):boolean -- Binds the GPU to the screen with the specified address."}
function obj.bind(address, reset)
	cprint("gpu.bind", address, reset)
	compCheckArg(1,address,"string")
	compCheckArg(2,reset,"boolean","nil")
	if reset == nil then
		reset = true
	end
	local thing = component.exists(address)
	if thing == nil then
		return nil, "invalid address"
	elseif thing ~= "screen" then
		return nil, "not a screen"
	end
	bindaddress = address
	if reset then
		local smw, smh = component.cecinvoke(bindaddress, "maxResolution")
		component.cecinvoke(bindaddress, "setResolution", math.min(smw, maxwidth), math.min(smh, maxheight))
		component.cecinvoke(bindaddress, "setDepth", math.min(component.cecinvoke(bindaddress, "maxDepth"), maxtier))
		component.cecinvoke(bindaddress, "setForeground", 0xFFFFFF)
		component.cecinvoke(bindaddress, "setBackground", 0x000000)
		buffers = {}
		usedMemory = 0
		activeBufferIdx = 0
	end
end

mai.getForeground = {direct = true, doc = "function():number, boolean -- Get the current foreground color and whether it's from the palette or not."}
function obj.getForeground()
	cprint("gpu.getForeground")
	if bindaddress == nil then
		return nil, "no screen"
	end
	if activeBufferIdx == 0 then
		return component.cecinvoke(bindaddress, "getForeground")
	else
		return buffers[activeBufferIdx].fg
	end
end


mai.setForeground = {direct = true, doc = "function(value:number[, palette:boolean]):number, number or nil -- Sets the foreground color to the specified value. Optionally takes an explicit palette index. Returns the old value and if it was from the palette its palette index."}
function obj.setForeground(value, palette)
	cprint("gpu.setForeground", value, palette)
	if not consumeGraphicCallBudget(setForegroundCosts[maxtier]) then return end
	compCheckArg(1,value,"number")
	compCheckArg(2,palette,"boolean","nil")
	if bindaddress == nil then
		return nil, "no screen"
	end
	if palette and component.cecinvoke(bindaddress, "getDepth") == 1 then
		error("color palette not suppported", 0)
	end
	if palette == true and (value < 0 or value > 15) then
		error("invalid palette index", 0)
	end
	if activeBufferIdx == 0 then
		return component.cecinvoke(bindaddress, "setForeground", value, palette)
	else
		buffers[activeBufferIdx].fg = value
	end
end

mai.getBackground = {direct = true, doc = "function():number, boolean -- Get the current background color and whether it's from the palette or not."}
function obj.getBackground()
	cprint("gpu.getBackground")
	if bindaddress == nil then
		return nil, "no screen"
	end
	if activeBufferIdx == 0 then
		return component.cecinvoke(bindaddress, "getBackground")
	else
		return buffers[activeBufferIdx].bg
	end
end

mai.setBackground = {direct = true, doc = "function(value:number[, palette:boolean]):number, number or nil -- Sets the background color to the specified value. Optionally takes an explicit palette index. Returns the old value and if it was from the palette its palette index."}
function obj.setBackground(value, palette)
	cprint("gpu.setBackground", value, palette)
	if not consumeGraphicCallBudget(setBackgroundCosts[maxtier]) then return end
	compCheckArg(1,value,"number")
	compCheckArg(2,palette,"boolean","nil")
	if bindaddress == nil then
		return nil, "no screen"
	end
	if palette and component.cecinvoke(bindaddress, "getDepth") == 1 then
		error("color palette not suppported", 0)
	end
	value = math.floor(value)
	if palette and (value < 0 or value > 15) then
		error("invalid palette index", 0)
	end
	if activeBufferIdx == 0 then
		return component.cecinvoke(bindaddress, "setBackground", value, palette)
	else
		buffers[activeBufferIdx].bg = value
	end
end

mai.getDepth = {direct = true, doc = "function():number -- Returns the currently set color depth."}
function obj.getDepth()
	cprint("gpu.getDepth")
	return depthTbl[component.cecinvoke(bindaddress, "getDepth")]
end

mai.setDepth = {doc = "function(depth:number):number -- Set the color depth. Returns the previous value."}
function obj.setDepth(depth)
	cprint("gpu.setDepth", depth)
	compCheckArg(1,depth,"number")
	if bindaddress == nil then
		return nil, "no screen"
	end
	depth = math.floor(depth)
	local scrmax = component.cecinvoke(bindaddress, "maxDepth")
	if rdepthTbl[depth] == nil or rdepthTbl[depth] > math.max(scrmax, maxtier) then
		error("unsupported depth", 0)
	end
	local old = depthNames[component.cecinvoke(bindaddress, "getDepth")]
	component.cecinvoke(bindaddress, "setDepth", rdepthTbl[depth])
	return old
end

mai.maxDepth = {direct = true, doc = "function():number -- Get the maximum supported color depth."}
function obj.maxDepth()
	cprint("gpu.maxDepth")
	return depthTbl[math.min(component.cecinvoke(bindaddress, "maxDepth"), maxtier)]
end

mai.fill = {direct = true, doc = "function(x:number, y:number, width:number, height:number, char:string):boolean -- Fills a portion of the screen at the specified position with the specified size with the specified character."}
function obj.fill(x, y, width, height, char)
	cprint("gpu.fill", x, y, width, height, char)
	if not consumeGraphicCallBudget(fillCosts[maxtier]) then return end
	compCheckArg(1,x,"number")
	compCheckArg(2,y,"number")
	compCheckArg(3,width,"number")
	compCheckArg(4,height,"number")
	compCheckArg(5,char,"string")
	if bindaddress == nil then
		return nil, "no screen"
	end
	if utf8.len(char) ~= 1 then
		return nil, "invalid fill value"
	end
	if activeBufferIdx == 0 then
		return component.cecinvoke(bindaddress, "fill", x, y, width, height, char)
	else
		local buf = buffers[activeBufferIdx]
		for dx=0, width-1 do
			for dy=0, height-1 do
				bufferSet(buf, x+dx, y+dy, char)
			end
		end
		return true
	end
end

mai.getScreen = {direct = true, doc = "function():string -- Get the address of the screen the GPU is currently bound to."}
function obj.getScreen()
	cprint("gpu.getScreen")
	return bindaddress
end

mai.getResolution = {direct = true, doc = "function():number, number -- Get the current screen resolution."}
function obj.getResolution()
	cprint("gpu.getResolution")
	if bindaddress == nil then
		return nil, "no screen"
	end
	return component.cecinvoke(bindaddress, "getResolution")
end

mai.setResolution = {doc = "function(width:number, height:number):boolean -- Set the screen resolution. Returns true if the resolution changed."}
function obj.setResolution(width, height)
	cprint("gpu.setResolution", width, height)
	compCheckArg(1,width,"number")
	compCheckArg(2,height,"number")
	if bindaddress == nil then
		return nil, "no screen"
	end
	local smw,smh = component.cecinvoke(bindaddress, "maxResolution")
	smw,smh = math.min(smw,maxwidth),math.min(smh,maxheight)
	if width <= 0 or width >= smw + 1 or height <= 0 or height >= smh + 1 then
		error("unsupported resolution", 0)
	end
	return component.cecinvoke(bindaddress, "setResolution", width, height)
end

mai.maxResolution = {direct = true, doc = "function():number, number -- Get the maximum screen resolution."}
function obj.maxResolution()
	cprint("gpu.maxResolution")
	if bindaddress == nil then
		return nil, "no screen"
	end
	local smw,smh = component.cecinvoke(bindaddress, "maxResolution")
	return math.min(smw, maxwidth), math.min(smh, maxheight)
end

--STUB: Actually Implement viewport
mai.getViewport = {direct = true, doc = "function():number, number -- Get the current viewport resolution."}
function obj.getViewport()
	cprint("gpu.getViewport")
	if bindaddress == nil then
		return nil, "no screen"
	end
	return component.cecinvoke(bindaddress, "getResolution")
end

--STUB: Actually Implement viewport
mai.setViewport = {doc = "function(width:number, height:number):boolean -- Set the viewport resolution. Returns true if the resolution changed."}
function obj.setViewport(width, height)
	cprint("gpu.setViewport", width, height)
	compCheckArg(1,width,"number")
	compCheckArg(2,height,"number")
	if bindaddress == nil then
		return nil, "no screen"
	end
	local smw,smh = component.cecinvoke(bindaddress, "maxResolution")
	smw,smh = math.min(smw,maxwidth),math.min(smh,maxheight)
	if width <= 0 or width >= smw + 1 or height <= 0 or height >= smh + 1 then
		error("unsupported viewport size", 0)
	end
	return component.cecinvoke(bindaddress, "setResolution", width, height)
end

mai.getPaletteColor = {direct = true, doc = "function(index:number):number -- Get the palette color at the specified palette index."}
function obj.getPaletteColor(index)
	cprint("gpu.getPaletteColor", index)
	compCheckArg(1,index,"number")
	if bindaddress == nil then
		return nil, "no screen"
	end
	if component.cecinvoke(bindaddress, "getDepth") == 1 then
		return "palette not available"
	end
	index = math.floor(index)
	if index < 0 or index > 15 then
		error("invalid palette index", 0)
	end
	return component.cecinvoke(bindaddress, "getPaletteColor", index)
end

mai.setPaletteColor = {direct = true, doc = "function(index:number, color:number):number -- Set the palette color at the specified palette index. Returns the previous value."}
function obj.setPaletteColor(index, color)
	cprint("gpu.setPaletteColor", index, color)
	if not machine.consumeCallBudget(setPaletteColorCosts[maxtier]) then return end
	compCheckArg(1,index,"number")
	compCheckArg(2,color,"number")
	if bindaddress == nil then
		return nil, "no screen"
	end
	if component.cecinvoke(bindaddress, "getDepth") == 1 then
		return "palette not available"
	end
	index = math.floor(index)
	if index < 0 or index > 15 then
		error("invalid palette index", 0)
	end
	return component.cecinvoke(bindaddress, "setPaletteColor", index, color)
end

mai.get = {direct = true, doc = "function(x:number, y:number):string, number, number, number or nil, number or nil -- Get the value displayed on the screen at the specified index, as well as the foreground and background color. If the foreground or background is from the palette, returns the palette indices as fourth and fifth results, else nil, respectively."}
function obj.get(x, y)
	cprint("gpu.get", x, y)
	compCheckArg(1,x,"number")
	compCheckArg(2,y,"number")
	if bindaddress == nil then
		return nil, "no screen"
	end
	local w,h = obj.getResolution()
	if x < 1 or x >= w+1 or y < 1 or y >= h+1 then
		error("index out of bounds", 0)
	end
	if activeBufferIdx == 0 then
		return component.cecinvoke(bindaddress, "get", x, y)
	else
		return bufferGet(buffers[activeBufferIdx], x, y), nil, nil
	end
end

mai.set = {direct = true, doc = "function(x:number, y:number, value:string[, vertical:boolean]):boolean -- Plots a string value to the screen at the specified position. Optionally writes the string vertically."}
function obj.set(x, y, value, vertical)
	cprint("gpu.set", x, y, value, vertical)
	if not consumeGraphicCallBudget(setCosts[maxtier]) then return end
	compCheckArg(1,x,"number")
	compCheckArg(2,y,"number")
	compCheckArg(3,value,"string")
	compCheckArg(4,vertical,"boolean","nil")
	if bindaddress == nil then
		return nil, "no screen"
	end
	if activeBufferIdx == 0 then
		return component.cecinvoke(bindaddress, "set", x, y, value, vertical)
	else
		for i=1, utf8.len(value) do
			local ch = utf8.sub(value, i, i)
			if vertical then
				bufferSet(buffers[activeBufferIdx], x, y+i-1, ch)
			else
				bufferSet(buffers[activeBufferIdx], x+i-1, y, ch)
			end
		end
		return true
	end
end

mai.copy = {direct = true, doc = "function(x:number, y:number, width:number, height:number, tx:number, ty:number):boolean -- Copies a portion of the screen from the specified location with the specified size by the specified translation."}
function obj.copy(x, y, width, height, tx, ty)
	cprint("gpu.copy", x, y, width, height, tx, ty)
	if not machine.consumeCallBudget(copyCosts[maxtier]) then return end
	compCheckArg(1,x,"number")
	compCheckArg(2,y,"number")
	compCheckArg(3,width,"number")
	compCheckArg(4,height,"number")
	compCheckArg(5,tx,"number")
	compCheckArg(6,ty,"number")
	if bindaddress == nil then
		return nil, "no screen"
	end
	return component.cecinvoke(bindaddress, "copy", x, y, width, height, tx, ty)
end

return obj,nil,mai
