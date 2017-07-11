local address, _, directory, label, tier = ...

compCheckArg(1,directory,"string","nil")
compCheckArg(2,label,"string","nil")
compCheckArg(3,tier,"number")

if directory == nil then
	directory = elsa.filesystem.getSaveDirectory()
end

local savePath = directory .. "/" .. address .. ".bin"
local platterCount = tier == 3 and 6 or tier == 2 and 4 or 2
local capacity = (tier == 3 and 4096 or tier == 2 and 2048 or 1024) * 1024
local sectorSize = 512
local sectorCount = capacity / sectorSize
local sectorsPerPlatter = sectorCount / platterCount
local headPos = 0
local data

local mai = {}
local obj = {}

local readSectorCosts = {1.0 / 10, 1.0 / 20, 1.0 / 30, 1.0 / 40, 1.0 / 50, 1.0 / 60}
local writeSectorCosts = {1.0 / 5, 1.0 / 10, 1.0 / 15, 1.0 / 20, 1.0 / 25, 1.0 / 30}
local readByteCosts = {1.0 / 48, 1.0 / 64, 1.0 / 80, 1.0 / 96, 1.0 / 112, 1.0 / 128}
local writeByteCosts = {1.0 / 24, 1.0 / 32, 1.0 / 40, 1.0 / 48, 1.0 / 56, 1.0 / 64}

local function save()
	local file = elsa.filesystem.newFile(savePath, "w")
	file:write(data)
	file:close()
end

local function load()
	if not elsa.filesystem.exists(savePath) then
		data = string.rep(string.char(0), capacity)
		return
	end
	local file = elsa.filesystem.newFile(savePath, "r")
	data = file:read("*a")
	file:close()
end

load()

local function validateSector(sector)
	if sector < 0 or sector >= sectorCount then
		error("invalid offset, not in a usable sector")
	end
	return sector
end

local function offsetSector(sector)
	return sector / sectorSize
end

local function sectorOffset(sector)
	return sector * sectorSize
end

local function checkSector(sector)
	return validateSector(sector - 1)
end

local function checkSectorR(sector)
	return validateSector(offsetSector(sector))
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
	return string.sub(data, sectorOffset(s), sectorOffset(s) + sectorSize)
end

mai.writeSector = {direct = true, doc = "function(sector:number, value:string) -- Write the specified contents to the specified sector."}
function obj.writeSector(sector, value)
	cprint("drive.writeSector", sector, value)
	compCheckArg(1, sector, "number")
	compCheckArg(1, value, "string")
	if not machine.consumeCallBudget(writeSectorCosts[speed]) then return end
    local s = moveToSector(checkSector(sector))
    local a = string.sub(data, 1, sectorOffset(s))
    local b = string.sub(data, sectorOffset(s) + math.min(sectorSize, #value) + 1, capacity)
    data = a .. value .. b
    save()
end

mai.readByte = {direct = true, doc = "function(offset:number):number -- Read a single byte at the specified offset."}
function obj.readByte(offset)
	cprint("drive.readByte", offset)
	compCheckArg(1, offset, "number")
	if not machine.consumeCallBudget(readByteCosts[speed]) then return end
	local s = moveToSector(checkSectorR(offset))
	return string.byte(string.sub(data, sectorOffset(s), sectorOffset(s)))
end

mai.writeByte = {direct = true, doc = "function(offset:number, value:number) -- Write a single byte to the specified offset."}
function obj.writeByte(offset, value)
	cprint("drive.writeByte", offset, value)
	compCheckArg(1, offset, "number")
	compCheckArg(1, value, "number")
	if not machine.consumeCallBudget(writeByteCosts[speed]) then return end
	local s = moveToSector(checkSectorR(offset))
    local a = string.sub(data, 1, sectorOffset(s))
    local b = string.sub(data, sectorOffset(s) + 2, capacity)
    data = a .. string.char(value) .. b
    save()
end


return obj, nil, mai
