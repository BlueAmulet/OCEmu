local address, slot, filename = ...

local code = love.filesystem.read(filename)
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
	data = newdata -- TODO
end
function obj.getDataSize() -- Get the storage capacity of this EEPROM.
	cprint("eeprom.getDataSize")
	return math.huge -- STUB
end
function obj.getSize() -- Get the storage capacity of this EEPROM.
	cprint("eeprom.getSize")
	return math.huge -- STUB
end
function obj.getLabel() -- Get the label of the EEPROM.
	cprint("eeprom.getLabel")
	return label
end
function obj.setLabel(newlabel) -- Set the label of the EEPROM.
	cprint("eeprom.setLabel", newlabel)
	label = newlabel -- TODO
end
function obj.getChecksum() -- Get the checksum of the data on this EEPROM.
	cprint("eeprom.getChecksum")
	return "1badbabe" -- STUB
end
function obj.get() -- Get the currently stored byte array.
	cprint("eeprom.get")
	return code
end
function obj.set(newcode) -- Overwrite the currently stored byte array.
	cprint("eeprom.set", newcode)
	code = newcode -- TODO
end
function obj.makeReadonly(checksum) -- Make this EEPROM readonly if it isn't already. This process cannot be reversed!
	--STUB
	print("eeprom.makeReadonly", checksum)
end

local cec = {}

return obj,cec
