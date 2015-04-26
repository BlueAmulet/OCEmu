local ffi = require("ffi")
local bit32 = require("bit32")

local s_crc32 = ffi.new('const uint32_t[16]', 0x00000000, 0x1db71064, 0x3b6e20c8, 0x26d930ac, 0x76dc4190, 0x6b6b51f4, 0x4db26158, 0x5005713c, 0xedb88320, 0xf00f9344, 0xd6d6a3e8, 0xcb61b38c, 0x9b64c2b0, 0x86d3d2d4, 0xa00ae278, 0xbdbdf21c)

return function(str)
	local crc = 0
	local len = #str
	str = ffi.cast('const uint8_t*', str)
	crc = bit32.bnot(crc)
	for i = 0, len-1 do
		crc = bit32.bxor(bit32.rshift(crc, 4), s_crc32[bit32.bxor(bit32.band(crc, 0xF), bit32.band(str[i], 0xF))])
		crc = bit32.bxor(bit32.rshift(crc, 4), s_crc32[bit32.bxor(bit32.band(crc, 0xF), bit32.rshift(str[i], 4))])
	end
	return bit32.bnot(crc)
end

