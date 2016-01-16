local address, _, maxwidth, maxheight, maxtier = ...
compCheckArg(1,maxwidth,"number")
compCheckArg(2,maxheight,"number")
compCheckArg(3,maxtier,"number")

local utf8 = require("lua-utf8")

local bindaddress
local depthTbl = {1,4,8}
local rdepthTbl = {1,[4]=2,[8]=3}
local depthNames = {"OneBit","FourBit","EightBit"}

-- gpu component
local obj = {}

function obj.bind(address) -- Binds the GPU to the screen with the specified address.
	cprint("gpu.bind", address)
	compCheckArg(1,address,"string")
	local thing = component.exists(address)
	if thing == nil then
		return nil, "invalid address"
	elseif thing ~= "screen" then
		return nil, "not a screen"
	end
	bindaddress = address
end
function obj.getForeground() -- Get the current foreground color and whether it's from the palette or not.
	cprint("gpu.getForeground")
	if bindaddress == nil then
		return nil, "no screen"
	end
	return component.cecinvoke(bindaddress, "getForeground")
end
function obj.setForeground(value, palette) -- Sets the foreground color to the specified value. Optionally takes an explicit palette index. Returns the old value and if it was from the palette its palette index.
	cprint("gpu.setForeground", value, palette)
	compCheckArg(1,value,"number")
	compCheckArg(2,palette,"boolean","nil")
	if bindaddress == nil then
		return nil, "no screen"
	end
	if palette and component.cecinvoke(bindaddress, "getDepth") == 1 then
		error("color palette not suppported",3)
	end
	if palette == true and (value < 0 or value > 15) then
		error("invalid palette index",3)
	end
	return component.cecinvoke(bindaddress, "setForeground", value, palette)
end
function obj.getBackground() -- Get the current background color and whether it's from the palette or not.
	cprint("gpu.getBackground")
	if bindaddress == nil then
		return nil, "no screen"
	end
	return component.cecinvoke(bindaddress, "getBackground")
end
function obj.setBackground(value, palette) -- Sets the background color to the specified value. Optionally takes an explicit palette index. Returns the old value and if it was from the palette its palette index.
	cprint("gpu.setBackground", value, palette)
	compCheckArg(1,value,"number")
	compCheckArg(2,palette,"boolean","nil")
	if bindaddress == nil then
		return nil, "no screen"
	end
	if palette and component.cecinvoke(bindaddress, "getDepth") == 1 then
		error("color palette not suppported",3)
	end
	value = math.floor(value)
	if palette and (value < 0 or value > 15) then
		error("invalid palette index",3)
	end
	return component.cecinvoke(bindaddress, "setBackground", value, palette)
end
function obj.getDepth() -- Returns the currently set color depth.
	cprint("gpu.getDepth")
	return depthTbl[component.cecinvoke(bindaddress, "getDepth")]
end
function obj.setDepth(depth) -- Set the color depth. Returns the previous value.
	cprint("gpu.setDepth", depth)
	compCheckArg(1,depth,"number")
	if bindaddress == nil then
		return nil, "no screen"
	end
	depth = math.floor(depth)
	local scrmax = component.cecinvoke(bindaddress, "maxDepth")
	if rdepthTbl[depth] == nil or rdepthTbl[depth] > math.max(scrmax, maxtier) then
		error("unsupported depth",3)
	end
	local old = depthNames[component.cecinvoke(bindaddress, "getDepth")]
	component.cecinvoke(bindaddress, "setDepth", rdepthTbl[depth])
	return old
end
function obj.maxDepth() -- Get the maximum supported color depth.
	cprint("gpu.maxDepth")
	return depthTbl[math.min(component.cecinvoke(bindaddress, "maxDepth"), maxtier)]
end
function obj.fill(x, y, width, height, char) -- Fills a portion of the screen at the specified position with the specified size with the specified character.
	cprint("gpu.fill", x, y, width, height, char)
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
	return component.cecinvoke(bindaddress, "fill", x, y, width, height, char)
end
function obj.getScreen() -- Get the address of the screen the GPU is currently bound to.
	cprint("gpu.getScreen")
	return bindaddress
end
function obj.getResolution() -- Get the current screen resolution.
	cprint("gpu.getResolution")
	if bindaddress == nil then
		return nil, "no screen"
	end
	return component.cecinvoke(bindaddress, "getResolution")
end
function obj.setResolution(width, height) -- Set the screen resolution. Returns true if the resolution changed.
	cprint("gpu.setResolution", width, height)
	compCheckArg(1,width,"number")
	compCheckArg(2,height,"number")
	if bindaddress == nil then
		return nil, "no screen"
	end
	local smw,smh = component.cecinvoke(bindaddress, "maxResolution")
	smw,smh = math.min(smw,maxwidth),math.min(smh,maxheight)
	if width <= 0 or width >= smw + 1 or height <= 0 or height >= smh + 1 then
		error("unsupported resolution",3)
	end
	return component.cecinvoke(bindaddress, "setResolution", width, height)
end
function obj.maxResolution() -- Get the maximum screen resolution.
	cprint("gpu.maxResolution")
	if bindaddress == nil then
		return nil, "no screen"
	end
	local smw,smh = component.cecinvoke(bindaddress, "maxResolution")
	return math.min(smw, maxwidth), math.min(smh, maxheight)
end
--STUB: Actually Implement viewport
function obj.getViewport() -- Get the current viewport resolution.
	cprint("gpu.getViewport")
	if bindaddress == nil then
		return nil, "no screen"
	end
	return component.cecinvoke(bindaddress, "getResolution")
end
--STUB: Actually Implement viewport
function obj.setViewport(width, height) -- Set the viewport resolution. Returns true if the resolution changed.
	cprint("gpu.setViewport", width, height)
	compCheckArg(1,width,"number")
	compCheckArg(2,height,"number")
	if bindaddress == nil then
		return nil, "no screen"
	end
	local smw,smh = component.cecinvoke(bindaddress, "maxResolution")
	smw,smh = math.min(smw,maxwidth),math.min(smh,maxheight)
	if width <= 0 or width >= smw + 1 or height <= 0 or height >= smh + 1 then
		error("unsupported viewport size",3)
	end
	return component.cecinvoke(bindaddress, "setResolution", width, height)
end
function obj.getPaletteColor(index) -- Get the palette color at the specified palette index.
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
		error("invalid palette index",3)
	end
	return component.cecinvoke(bindaddress, "getPaletteColor", index)
end
function obj.setPaletteColor(index, color) -- Set the palette color at the specified palette index. Returns the previous value.
	cprint("gpu.setPaletteColor", index, color)
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
		error("invalid palette index",3)
	end
	return component.cecinvoke(bindaddress, "setPaletteColor", index, color)
end
function obj.get(x, y) -- Get the value displayed on the screen at the specified index, as well as the foreground and background color. If the foreground or background is from the palette, returns the palette indices as fourth and fifth results, else nil, respectively.
	cprint("gpu.get", x, y)
	compCheckArg(1,x,"number")
	compCheckArg(2,y,"number")
	if bindaddress == nil then
		return nil, "no screen"
	end
	local w,h = component.cecinvoke(bindaddress, "getResolution")
	if x < 1 or x >= w+1 or y < 1 or y >= h+1 then
		error("index out of bounds",3)
	end
	return component.cecinvoke(bindaddress, "get", x, y)
end
function obj.set(x, y, value, vertical) -- Plots a string value to the screen at the specified position. Optionally writes the string vertically.
	cprint("gpu.set", x, y, value, vertical)
	compCheckArg(1,x,"number")
	compCheckArg(2,y,"number")
	compCheckArg(3,value,"string")
	compCheckArg(4,vertical,"boolean","nil")
	if bindaddress == nil then
		return nil, "no screen"
	end
	return component.cecinvoke(bindaddress, "set", x, y, value, vertical)
end
function obj.copy(x, y, width, height, tx, ty) -- Copies a portion of the screen from the specified location with the specified size by the specified translation.
	cprint("gpu.copy", x, y, width, height, tx, ty)
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

local cec = {}

local doc = {
	["bind"]="function(address:string):boolean -- Binds the GPU to the screen with the specified address.",
	["getForeground"]="function():number, boolean -- Get the current foreground color and whether it's from the palette or not.",
	["setForeground"]="function(value:number[, palette:boolean]):number, number or nil -- Sets the foreground color to the specified value. Optionally takes an explicit palette index. Returns the old value and if it was from the palette its palette index.",
	["getBackground"]="function():number, boolean -- Get the current background color and whether it's from the palette or not.",
	["setBackground"]="function(value:number[, palette:boolean]):number, number or nil -- Sets the background color to the specified value. Optionally takes an explicit palette index. Returns the old value and if it was from the palette its palette index.",
	["getDepth"]="function():number -- Returns the currently set color depth.",
	["setDepth"]="function(depth:number):number -- Set the color depth. Returns the previous value.",
	["maxDepth"]="function():number -- Get the maximum supported color depth.",
	["fill"]="function(x:number, y:number, width:number, height:number, char:string):boolean -- Fills a portion of the screen at the specified position with the specified size with the specified character.",
	["getScreen"]="function():string -- Get the address of the screen the GPU is currently bound to.",
	["getResolution"]="function():number, number -- Get the current screen resolution.",
	["setResolution"]="function(width:number, height:number):boolean -- Set the screen resolution. Returns true if the resolution changed.",
	["maxResolution"]="function():number, number -- Get the maximum screen resolution.",
	["getViewport"]="function():number, number -- Get the current viewport resolution.",
	["setViewport"]="function(width:number, height:number):boolean -- Set the viewport resolution. Returns true if the resolution changed.",
	["getPaletteColor"]="function(index:number):number -- Get the palette color at the specified palette index.",
	["setPaletteColor"]="function(index:number, color:number):number -- Set the palette color at the specified palette index. Returns the previous value.",
	["get"]="function(x:number, y:number):string, number, number, number or nil, number or nil -- Get the value displayed on the screen at the specified index, as well as the foreground and background color. If the foreground or background is from the palette, returns the palette indices as fourth and fifth results, else nil, respectively.",
	["set"]="function(x:number, y:number, value:string[, vertical:boolean]):boolean -- Plots a string value to the screen at the specified position. Optionally writes the string vertically.",
	["copy"]="function(x:number, y:number, width:number, height:number, tx:number, ty:number):boolean -- Copies a portion of the screen from the specified location with the specified size by the specified translation.",
}

return obj,cec,doc
