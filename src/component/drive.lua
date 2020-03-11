local address, _, filename, label, tier = ...

compCheckArg(1,filename,"string","nil")
compCheckArg(2,label,"string","nil")
compCheckArg(3,tier,"number")

if type(filename) == "string" and not elsa.filesystem.exists(filename) then	
	error("no such file", 3)
end

local directory = elsa.filesystem.getSaveDirectory() .. "/" .. address
if not elsa.filesystem.exists(directory) then
	elsa.filesystem.createDirectory(directory)
end

local savePath = directory .. "/data.bin"
local platterCount = tier == 3 and 8 or tier == 2 and 4 or 2
local capacity = (tier == 3 and 4 or tier == 2 and 2 or 1) * 1024 * 1024
local sectorSize = 512
local sectorCount = capacity / sectorSize
local sectorsPerPlatter = sectorCount / platterCount
local headPos = 0
local data

local readSectorCosts = {1/10, 1/20, 1/30, 1/40, 1/50, 1/60}
local writeSectorCosts = {1/5, 1/10, 1/15, 1/20, 1/25, 1/30}
local readByteCosts = {1/48, 1/64, 1/80, 1/96, 1/112, 1/128}
local writeByteCosts = {1/24, 1/32, 1/40, 1/48, 1/56, 1/64}

local function save()
	local file = elsa.filesystem.newFile(savePath, "w")
	file:write(data)
	file:close()
end

local function load(filename)
	if elsa.filesystem.exists(filename) then
		local file = elsa.filesystem.newFile(filename, "r")
		data = file:read("*a"):sub(1, capacity)
		file:close()
		data = data .. string.rep("\0", capacity - #data)
		return true
	end
	return false
end

if not load(savePath) then
	if type(filename) ~= "string" or not load(filename) then
		data = string.rep("\0", capacity)
	end
	save()
end

local function validateSector(sector)
	if sector < 0 or sector >= sectorCount then
		error("invalid offset, not in a usable sector", 0)
	end
	return sector
end

local function offsetSector(offset)
	return offset / sectorSize
end

local function sectorOffset(sector)
	return sector * sectorSize
end

local function checkSector(sector)
	return validateSector(sector - 1)
end

local function checkOffset(offset)
	return validateSector(offsetSector(offset - 1))
end

local function sectorToHeadPos(sector)
	return sector % sectorsPerPlatter
end

local function moveToSector(sector)
	local newHeadPos = sectorToHeadPos(sector)
	if headPos ~= newHeadPos then
		headPos = newHeadPos
	end
	return sector
end

local mai = {}
local obj = {}

mai.getLabel = {direct = true, doc = "function():string -- Get the current label of the drive."}
function obj.getLabel()
	cprint("drive.getLabel")
    return label
end

mai.setLabel = {doc = "function(value:string):string -- Sets the label of the drive. Returns the new value, which may be truncated."}
function obj.setLabel(value)
	cprint("drive.setLabel", value)
	compCheckArg(1, value, "string")
	value = value:sub(1,16)
	if label ~= value then
		label = value
		for _, v in pairs(settings.components) do
			if v[1] == "drive" and v[2] == address then
				v[5] = label
			end
		end
		config.save()
	end
end

mai.getCapacity = {direct = true, doc = "function():number -- Returns the total capacity of the drive, in bytes."}
function obj.getCapacity()
	cprint("drive.getCapacity")
	return capacity
end

mai.getSectorSize = {direct = true, doc = "function():number -- Returns the size of a single sector on the drive, in bytes."}
function obj.getSectorSize()
	cprint("drive.getSectorSize")
	return sectorSize
end

mai.getPlatterCount = {direct = true, doc = "function():number -- Returns the number of platters in the drive."}
function obj.getPlatterCount()
	cprint("drive.getPlatterCount")
	return platterCount
end

mai.readSector = {direct = true, doc = "function(sector:number):string -- Read the current contents of the specified sector."}
function obj.readSector(sector)
	cprint("drive.readSector", sector)
	compCheckArg(1, sector, "number")
	if not machine.consumeCallBudget(readSectorCosts[speed]) then return end
	local s = moveToSector(checkSector(sector))
	return data:sub(sectorOffset(s) + 1, sectorOffset(s) + sectorSize)
end

mai.writeSector = {direct = true, doc = "function(sector:number, value:string) -- Write the specified contents to the specified sector."}
function obj.writeSector(sector, value)
	cprint("drive.writeSector", sector, value)
	compCheckArg(1, sector, "number")
	compCheckArg(1, value, "string")
	if not machine.consumeCallBudget(writeSectorCosts[speed]) then return end
	value = value:sub(1, sectorSize)
    local s = moveToSector(checkSector(sector))
    local a = data:sub(1, sectorOffset(s))
    local b = data:sub(sectorOffset(s) + #value + 1)
    data = a .. value .. b
    save()
end

mai.readByte = {direct = true, doc = "function(offset:number):number -- Read a single byte at the specified offset."}
function obj.readByte(offset)
	cprint("drive.readByte", offset)
	compCheckArg(1, offset, "number")
	if not machine.consumeCallBudget(readByteCosts[speed]) then return end
	moveToSector(checkOffset(offset))
	local byte = data:sub(offset, offset):byte()
	if byte >= 128 then
		byte = byte - 256
	end
	return byte
end

mai.writeByte = {direct = true, doc = "function(offset:number, value:number) -- Write a single byte to the specified offset."}
function obj.writeByte(offset, value)
	cprint("drive.writeByte", offset, value)
	compCheckArg(1, offset, "number")
	compCheckArg(1, value, "number")
	if not machine.consumeCallBudget(writeByteCosts[speed]) then return end
	moveToSector(checkOffset(offset))
    local a = data:sub(1, offset - 1)
    local b = data:sub(offset + 1)
    data = a .. string.char(math.floor(value % 256)) .. b
    save()
end

return obj, nil, mai
