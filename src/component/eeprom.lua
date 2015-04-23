local address, slot, filename = ...

local code = elsa.filesystem.read(filename)
local data = ""
local label = "EEPROM"

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
	compCheckArg(1,newlabel,"string","nil")
	if newlabel == nil then newlabel = "EEPROM" end
	label = newlabel:sub(1,16)
	return label
end
function obj.getChecksum() -- Get the checksum of the data on this EEPROM.
	-- STUB
	cprint("eeprom.getChecksum")
	return "1badbabe"
end
function obj.get() -- Get the currently stored byte array.
	cprint("eeprom.get")
	return code
end
function obj.set(newcode) -- Overwrite the currently stored byte array.
	cprint("eeprom.set", newcode)
	compCheckArg(1,newcode,"string","nil")
	if newcode == nil then newcode = "" end
	if #newcode > 4096 then
		error("not enough space",3)
	end
	code = newcode
end
function obj.makeReadonly(checksum) -- Make this EEPROM readonly if it isn't already. This process cannot be reversed!
	--STUB
	print("eeprom.makeReadonly", checksum)
	compCheckArg(1,checksum,"string")
	if checksum ~= obj.getChecksum() then
		return nil, "incorrect checksum"
	end
	return false
end

local cec = {}

return obj,cec
