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
local mai = {}
local obj = {}

mai.bind = {doc = "function(address:string):boolean -- Binds the GPU to the screen with the specified address."}
function obj.bind(address)
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

mai.getForeground = {doc = "function():number, boolean -- Get the current foreground color and whether it's from the palette or not."}
function obj.getForeground()
	cprint("gpu.getForeground")
	if bindaddress == nil then
		return nil, "no screen"
	end
	return component.cecinvoke(bindaddress, "getForeground")
end


mai.setForeground = {doc = "function(value:number[, palette:boolean]):number, number or nil -- Sets the foreground color to the specified value. Optionally takes an explicit palette index. Returns the old value and if it was from the palette its palette index."}
function obj.setForeground(value, palette)
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

mai.getBackground = {doc = "function():number, boolean -- Get the current background color and whether it's from the palette or not."}
function obj.getBackground()
	cprint("gpu.getBackground")
	if bindaddress == nil then
		return nil, "no screen"
	end
	return component.cecinvoke(bindaddress, "getBackground")
end

mai.setBackground = {doc = "function(value:number[, palette:boolean]):number, number or nil -- Sets the background color to the specified value. Optionally takes an explicit palette index. Returns the old value and if it was from the palette its palette index."}
function obj.setBackground(value, palette)
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

mai.getDepth = {doc = "function():number -- Returns the currently set color depth."}
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
		error("unsupported depth",3)
	end
	local old = depthNames[component.cecinvoke(bindaddress, "getDepth")]
	component.cecinvoke(bindaddress, "setDepth", rdepthTbl[depth])
	return old
end

mai.maxDepth = {doc = "function():number -- Get the maximum supported color depth."}
function obj.maxDepth()
	cprint("gpu.maxDepth")
	return depthTbl[math.min(component.cecinvoke(bindaddress, "maxDepth"), maxtier)]
end

mai.fill = {doc = "function(x:number, y:number, width:number, height:number, char:string):boolean -- Fills a portion of the screen at the specified position with the specified size with the specified character."}
function obj.fill(x, y, width, height, char)
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

mai.getScreen = {doc = "function():string -- Get the address of the screen the GPU is currently bound to."}
function obj.getScreen()
	cprint("gpu.getScreen")
	return bindaddress
end

mai.getResolution = {doc = "function():number, number -- Get the current screen resolution."}
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
		error("unsupported resolution",3)
	end
	return component.cecinvoke(bindaddress, "setResolution", width, height)
end

mai.maxResolution = {doc = "function():number, number -- Get the maximum screen resolution."}
function obj.maxResolution()
	cprint("gpu.maxResolution")
	if bindaddress == nil then
		return nil, "no screen"
	end
	local smw,smh = component.cecinvoke(bindaddress, "maxResolution")
	return math.min(smw, maxwidth), math.min(smh, maxheight)
end

--STUB: Actually Implement viewport
mai.getViewport = {doc = "function():number, number -- Get the current viewport resolution."}
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
		error("unsupported viewport size",3)
	end
	return component.cecinvoke(bindaddress, "setResolution", width, height)
end

mai.getPaletteColor = {doc = "function(index:number):number -- Get the palette color at the specified palette index."}
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
		error("invalid palette index",3)
	end
	return component.cecinvoke(bindaddress, "getPaletteColor", index)
end

mai.setPaletteColor = {doc = "function(index:number, color:number):number -- Set the palette color at the specified palette index. Returns the previous value."}
function obj.setPaletteColor(index, color)
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

mai.get = {doc = "function(x:number, y:number):string, number, number, number or nil, number or nil -- Get the value displayed on the screen at the specified index, as well as the foreground and background color. If the foreground or background is from the palette, returns the palette indices as fourth and fifth results, else nil, respectively."}
function obj.get(x, y)
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

mai.set = {doc = "function(x:number, y:number, value:string[, vertical:boolean]):boolean -- Plots a string value to the screen at the specified position. Optionally writes the string vertically."}
function obj.set(x, y, value, vertical)
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

mai.copy = {doc = "function(x:number, y:number, width:number, height:number, tx:number, ty:number):boolean -- Copies a portion of the screen from the specified location with the specified size by the specified translation."}
function obj.copy(x, y, width, height, tx, ty)
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

return obj,nil,mai
