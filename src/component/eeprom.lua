local address, _, filename = ...
compCheckArg(1,filename,"string")
if not elsa.filesystem.exists(filename) then	
	error("no such file",3)
end

local crc32 = require("support.crc32")

local directory = elsa.filesystem.getSaveDirectory() .. "/" .. address
if not elsa.filesystem.exists(directory) then
	elsa.filesystem.createDirectory(directory)
end

local code = elsa.filesystem.read(filename)
local data = ""
local label = "EEPROM"
local readonly = false
if elsa.filesystem.exists(directory .. "/data.lua") then
	local fn, err = elsa.filesystem.load(directory .. "/data.lua","t",{})
	if not fn then
		cprint("Failed to unpersist eeprom @" .. address .. ": " .. err)
	else
		local ncode,ndata,nlabel,nread = fn()
		if type(ncode) ~= "string" or type(ndata) ~= "string" or type(nlabel) ~= "string" or type(nread) ~= "boolean" then
			cprint("Failed to unpersist eeprom @" .. address .. ": Invalid persist data")
			cprint("code) " .. type(ncode))
			cprint("data) " .. type(ndata))
			cprint("labl) " .. type(nlabel))
			cprint("read) " .. type(nread))
		else
			code,data,label,readonly = ncode,ndata,nlabel,nread
		end
	end
end

local function persist()
	local file, err = io.open(directory .. "/data.lua", "wb")
	if not file then
		cprint("Failed to persist eeprom @" .. address .. ": " .. err)
		return false
	end
	file:write(string.format("return %q,%q,%q,%s",code,data,label,tostring(readonly)):gsub("\\\n","\\n") .. "")
	file:close()
	return true
end

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
	persist()
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
	persist()
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
	persist()
end
function obj.makeReadonly(checksum) -- Make this EEPROM readonly if it isn't already. This process cannot be reversed!
	cprint("eeprom.makeReadonly", checksum)
	compCheckArg(1,checksum,"string")
	if checksum ~= obj.getChecksum() then
		return nil, "incorrect checksum"
	end
	readonly = true
	persist()
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
