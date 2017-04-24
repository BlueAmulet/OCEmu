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

local function persistfile(fname, data)
	local ok, err = elsa.filesystem.write(directory .. "/" .. fname, data)
	if not ok then
		cprint("Failed to persist eeprom(" .. fname .. ") @" .. address .. ": " .. err)
		return false
	end
	return ok, err
end

local function persistlock()
	if readonly then
		persistfile("readonly", "")
	else
		elsa.filesystem.remove(directory .. "/readonly")
	end
end

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
			persistfile("code.lua", code)
			persistfile("data.bin", data)
			persistfile("label.txt", label)
			persistlock()
			elsa.filesystem.remove(directory .. "/data.lua")
		end
	end
else
	if elsa.filesystem.exists(directory .. "/code.lua") then
		code = elsa.filesystem.read(directory .. "/code.lua")
	else
		persistfile("code.lua", code)
	end
	if elsa.filesystem.exists(directory .. "/data.bin") then
		data = elsa.filesystem.read(directory .. "/data.bin")
	else
		persistfile("data.bin", data)
	end
	if elsa.filesystem.exists(directory .. "/label.txt") then
		label = elsa.filesystem.read(directory .. "/label.txt")
	else
		persistfile("label.txt", label)
	end
	readonly = elsa.filesystem.exists(directory .. "/readonly")
end

-- eeprom component
local mai = {}
local obj = {}

mai.getData = {direct = true, doc = "function():string -- Get the currently stored byte array."}
function obj.getData()
	cprint("eeprom.getData")
	return data
end

mai.setData = {doc = "function(data:string) -- Overwrite the currently stored byte array."}
function obj.setData(newdata)
	cprint("eeprom.setData", newdata)
	compCheckArg(1,newdata,"string","nil")
	if newdata == nil then newdata = "" end
	if #newdata > settings.eepromDataSize then
		error("not enough space", 0)
	end
	data = newdata
	persistfile("data.bin", data)
end

mai.getDataSize = {direct = true, doc = "function():string -- Get the storage capacity of this EEPROM."}
function obj.getDataSize()
	cprint("eeprom.getDataSize")
	return settings.eepromDataSize
end

mai.getSize = {direct = true, doc = "function():string -- Get the storage capacity of this EEPROM."}
function obj.getSize()
	cprint("eeprom.getSize")
	return settings.eepromSize
end

mai.getLabel = {direct = true, doc = "function():string -- Get the label of the EEPROM."}
function obj.getLabel()
	cprint("eeprom.getLabel")
	return label
end

mai.setLabel = {doc = "function(data:string):string -- Set the label of the EEPROM."}
function obj.setLabel(newlabel)
	cprint("eeprom.setLabel", newlabel)
	if readonly then
		return nil, "storage is readonly"
	end
	compCheckArg(1,newlabel,"string","nil")
	if newlabel == nil then newlabel = "EEPROM" end
	label = newlabel:sub(1,16)
	persistfile("label.txt", label)
	return label
end

mai.getChecksum = {direct = true, doc = "function():string -- Get the checksum of the data on this EEPROM."}
function obj.getChecksum()
	cprint("eeprom.getChecksum")
	return string.format("%08x", tonumber(crc32(code)))
end

mai.get = {direct = true, doc = "function():string -- Get the currently stored byte array."}
function obj.get() -- Get the currently stored byte array.
	cprint("eeprom.get")
	return code
end

mai.set = {doc = "function(data:string) -- Overwrite the currently stored byte array."}
function obj.set(newcode) -- Overwrite the currently stored byte array.
	cprint("eeprom.set", newcode)
	if readonly then
		return nil, "storage is readonly"
	end
	compCheckArg(1,newcode,"string","nil")
	if newcode == nil then newcode = "" end
	if #newcode > settings.eepromSize then
		error("not enough space", 0)
	end
	code = newcode
	persistfile("code.lua", code)
end

mai.makeReadonly = {direct = true, doc = "function(checksum:string):boolean -- Make this EEPROM readonly if it isn't already. This process cannot be reversed!"}
function obj.makeReadonly(checksum) -- Make this EEPROM readonly if it isn't already. This process cannot be reversed!
	cprint("eeprom.makeReadonly", checksum)
	compCheckArg(1,checksum,"string")
	if checksum ~= obj.getChecksum() then
		return nil, "incorrect checksum"
	end
	readonly = true
	persistlock()
	return true
end

return obj,nil,mai
