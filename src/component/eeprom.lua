local address, slot, filename = ...

local crc32 = require("support.crc32")

local code = elsa.filesystem.read(filename)
local data = ""
local label = "EEPROM"
local readonly = false

-- eeprom component
local obj = {}

function obj.getData() -- Get the currently stored byte array.
	cprint("eeprom.getData")
	return data
end
function obj.setData(newdata) -- Overwrite the currently stored byte array.
	cprint("eeprom.setData", newdata)
	compCheckArg(1,newdata,"string","nil")
	if newdata == nil then newdata = "" end
	if #newdata > 256 then
		error("not enough space",3)
	end
	data = newdata
end
function obj.getDataSize() -- Get the storage capacity of this EEPROM.
	cprint("eeprom.getDataSize")
	return 256
end
function obj.getSize() -- Get the storage capacity of this EEPROM.
	cprint("eeprom.getSize")
	return 4096
end
function obj.getLabel() -- Get the label of the EEPROM.
	cprint("eeprom.getLabel")
	return label
end
function obj.setLabel(newlabel) -- Set the label of the EEPROM.
	cprint("eeprom.setLabel", newlabel)
	if readonly then
		return nil, "storage is readonly"
	end
	compCheckArg(1,newlabel,"string","nil")
	if newlabel == nil then newlabel = "EEPROM" end
	label = newlabel:sub(1,16)
	return label
end
function obj.getChecksum() -- Get the checksum of the data on this EEPROM.
	cprint("eeprom.getChecksum")
	return string.format("%08x", tonumber(crc32(code)))
end
function obj.get() -- Get the currently stored byte array.
	cprint("eeprom.get")
	return code
end
function obj.set(newcode) -- Overwrite the currently stored byte array.
	cprint("eeprom.set", newcode)
	if readonly then
		return nil, "storage is readonly"
	end
	compCheckArg(1,newcode,"string","nil")
	if newcode == nil then newcode = "" end
	if #newcode > 4096 then
		error("not enough space",3)
	end
	code = newcode
end
function obj.makeReadonly(checksum) -- Make this EEPROM readonly if it isn't already. This process cannot be reversed!
	print("eeprom.makeReadonly", checksum)
	compCheckArg(1,checksum,"string")
	if checksum ~= obj.getChecksum() then
		return nil, "incorrect checksum"
	end
	readonly = true
	return true
end

local cec = {}

local doc = {
	["getData"]="function():string -- Get the currently stored byte array.",
	["setData"]="function(data:string) -- Overwrite the currently stored byte array.",
	["getDataSize"]="function():string -- Get the storage capacity of this EEPROM.",
	["getSize"]="function():string -- Get the storage capacity of this EEPROM.",
	["getLabel"]="function():string -- Get the label of the EEPROM.",
	["setLabel"]="function(data:string):string -- Set the label of the EEPROM.",
	["getChecksum"]="function():string -- Get the checksum of the data on this EEPROM.",
	["get"]="function():string -- Get the currently stored byte array.",
	["set"]="function(data:string) -- Overwrite the currently stored byte array.",
	["makeReadonly"]="function(checksum:string):boolean -- Make this EEPROM readonly if it isn't already. This process cannot be reversed!",
}

return obj,cec,doc
