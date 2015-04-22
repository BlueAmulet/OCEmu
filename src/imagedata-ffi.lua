--[[
This software is in the public domain. Where that dedication is not recognized,
you are granted a perpetual, irrevokable license to copy and modify this file
as you see fit.
]]

--[[
Replaces several ImageData methods with FFI implementations. This can result
in a performance increase of up to 60x when calling the methods, especially
in simple code which had to fall back to interpreted mode specifically because
the normal ImageData methods couldn't be compiled by the JIT.
]]

--[[
NOTE: This was written specifically for LÖVE 0.9.0 and 0.9.1. Future versions
of LÖVE may change ImageData (either internally or externally) enough to cause
these replacements to break horribly.
]]

--[[
Unlike LÖVE's regular ImageData methods, these are *NOT THREAD-SAFE!*
You *need* to do your own synchronization if you want to use ImageData in
threads with these methods.
]]

assert(love and love.image, "love.image is required")

if type(jit) ~= "table" or not jit.status() then
	-- LuaJIT's FFI is *much* slower than LOVE's regular methods when the JIT
	-- compiler is disabled.
	return
end

local tonumber, assert = tonumber, assert

local ffi = require("ffi")

pcall(ffi.cdef, [[
typedef struct ImageData_Pixel
{
	uint8_t r, g, b, a;
} ImageData_Pixel;
]])

local pixelptr = ffi.typeof("ImageData_Pixel *")

local function inside(x, y, w, h)
	return x >= 0 and x < w and y >= 0 and y < h
end

local imagedata_mt
if debug then
	imagedata_mt = debug.getregistry()["ImageData"]
else
	imagedata_mt = getmetatable(love.image.newImageData(1,1))
end

local _getWidth = imagedata_mt.__index.getWidth
local _getHeight = imagedata_mt.__index.getHeight
local _getDimensions = imagedata_mt.__index.getDimensions

-- Holds ImageData objects as keys, and information about the objects as values.
-- Uses weak keys so the ImageData objects can still be GC'd properly.
local id_registry = {__mode = "k"}

function id_registry:__index(imagedata)
	local width, height = _getDimensions(imagedata)
	local pointer = ffi.cast(pixelptr, imagedata:getPointer())
	local p = {width=width, height=height, pointer=pointer}
	self[imagedata] = p
	return p
end

setmetatable(id_registry, id_registry)


-- FFI version of ImageData:mapPixel, with no thread-safety.
local function ImageData_FFI_mapPixel(imagedata, func, ix, iy, iw, ih)
	local p = id_registry[imagedata]
	local idw, idh = p.width, p.height
	
	ix = ix or 0
	iy = iy or 0
	iw = iw or idw
	ih = ih or idh
	
	assert(inside(ix, iy, idw, idh) and inside(ix+iw-1, iy+ih-1, idw, idh), "Invalid rectangle dimensions")
	
	local pixels = p.pointer
	
	for y=iy, iy+ih-1 do
		for x=ix, ix+iw-1 do
			local p = pixels[y*idw+x]
			local r, g, b, a = func(x, y, tonumber(p.r), tonumber(p.g), tonumber(p.b), tonumber(p.a))
			pixels[y*idw+x].r = r
			pixels[y*idw+x].g = g
			pixels[y*idw+x].b = b
			pixels[y*idw+x].a = a == nil and 255 or a
		end
	end
end

-- FFI version of ImageData:getPixel, with no thread-safety.
local function ImageData_FFI_getPixel(imagedata, x, y)
	local p = id_registry[imagedata]
	assert(inside(x, y, p.width, p.height), "Attempt to get out-of-range pixel!")
	
	local pixel = p.pointer[y * p.width + x]
	return tonumber(pixel.r), tonumber(pixel.g), tonumber(pixel.b), tonumber(pixel.a)
end

-- FFI version of ImageData:setPixel, with no thread-safety.
local function ImageData_FFI_setPixel(imagedata, x, y, r, g, b, a)
	a = a == nil and 255 or a
	local p = id_registry[imagedata]
	assert(inside(x, y, p.width, p.height), "Attempt to set out-of-range pixel!")
	
	local pixel = p.pointer[y * p.width + x]
	pixel.r = r
	pixel.g = g
	pixel.b = b
	pixel.a = a
end

-- FFI version of ImageData:getWidth.
local function ImageData_FFI_getWidth(imagedata)
	return id_registry[imagedata].width
end

-- FFI version of ImageData:getHeight.
local function ImageData_FFI_getHeight(imagedata)
	return id_registry[imagedata].height
end

-- FFI version of ImageData:getDimensions.
local function ImageData_FFI_getDimensions(imagedata)
	local p = id_registry[imagedata]
	return p.width, p.height
end


-- Overwrite love's functions with the new FFI versions.
imagedata_mt.__index.mapPixel = ImageData_FFI_mapPixel
imagedata_mt.__index.getPixel = ImageData_FFI_getPixel
imagedata_mt.__index.setPixel = ImageData_FFI_setPixel
imagedata_mt.__index.getWidth = ImageData_FFI_getWidth
imagedata_mt.__index.getHeight = ImageData_FFI_getHeight
imagedata_mt.__index.getDimensions = ImageData_FFI_getDimensions
