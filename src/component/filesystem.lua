local address, slot, directory, readonly = ...

if not love.filesystem.exists(directory) then
	love.filesystem.createDirectory(directory)
end

if directory == "tmpfs" then
	computer.setTempAddress(address)
end

local label = ("/" .. directory):match(".*/(.+)")
local handles = {}

local function cleanPath(path)
	local path = path:gsub("\\", "/")

	local tPath = {}
	for part in path:gmatch("[^/]+") do
   		if part ~= "" and part ~= "." then
   			if part == ".." and #tPath > 0 and tPath[#tPath] ~= ".." then
   				table.remove(tPath)
   			else
   				table.insert(tPath, part:sub(1,255))
   			end
   		end
	end
	return table.concat(tPath, "/")
end

-- filesystem component
local obj = {}

function obj.read(handle, count) -- Reads up to the specified amount of data from an open file descriptor with the specified handle. Returns nil when EOF is reached.
	--TODO
	cprint("filesystem.read", handle, count)
	if count == math.huge then count = nil end
	local ret = { handles[handle]:read(count) }
	if ret[1] ~= nil then ret[2] = nil end
	if ret[1] == "" and count ~= 0 then ret[1] = nil end
	return table.unpack(ret)
end
function obj.lastModified(path) -- Returns the (real world) timestamp of when the object at the specified absolute path in the file system was modified.
	--STUB
	cprint("filesystem.lastModified", path)
end
function obj.spaceUsed() -- The currently used capacity of the file system, in bytes.
	--STUB
	cprint("filesystem.spaceUsed")
end
function obj.rename(from, to) -- Renames/moves an object from the first specified absolute path in the file system to the second.
	--STUB
	cprint("filesystem.rename", from, to)
end
function obj.close(handle) -- Closes an open file descriptor with the specified handle.
	--TODO
	cprint("filesystem.close", handle)
	handles[handle]:close()
	handles[handle] = nil
end
function obj.write(handle, value) -- Writes the specified data to an open file descriptor with the specified handle.
	--STUB
	cprint("filesystem.write", handle, value)
end
function obj.remove(path) -- Removes the object at the specified absolute path in the file system.
	--STUB
	cprint("filesystem.remove", path)
end
function obj.size(path) -- Returns the size of the object at the specified absolute path in the file system.
	--STUB
	cprint("filesystem.size", path)
end
function obj.seek(handle, whence, offset) -- Seeks in an open file descriptor with the specified handle. Returns the new pointer position.
	--STUB
	cprint("filesystem.seek", handle, whence, offset)
end
function obj.spaceTotal() -- The overall capacity of the file system, in bytes.
	--STUB
	cprint("filesystem.spaceTotal")
end
function obj.getLabel() -- Get the current label of the file system.
	--TODO
	cprint("filesystem.getLabel")
	return label
end
function obj.setLabel(value) -- Sets the label of the file system. Returns the new value, which may be truncated.
	--TODO
	cprint("filesystem.setLabel", value)
	label = value
end
function obj.open(path, mode) -- Opens a new file descriptor and returns its handle.
	--TODO
	cprint("filesystem.open", path, mode)
	if mode == nil then mode = "r" end
	compCheckArg(1,path,"string")
	compCheckArg(2,mode,"string")
	local file = love.filesystem.newFile(directory .. "/" .. path, mode:sub(1,1))
	if not file then return nil end
	while true do
		local rnddescrpt = math.random(1000000000,9999999999)
		if handles[rnddescrpt] == nil then
			handles[rnddescrpt] = file
			return rnddescrpt
		end
	end
end
function obj.exists(path) -- Returns whether an object exists at the specified absolute path in the file system.
	--TODO
	cprint("filesystem.exists", path)
	return love.filesystem.exists(directory .. "/" .. path)
end
function obj.list(path) -- Returns a list of names of objects in the directory at the specified absolute path in the file system.
	--TODO
	cprint("filesystem.list", path)
	local list = love.filesystem.getDirectoryItems(directory .. "/" .. path)
	for i = 1,#list do
		if love.filesystem.isDirectory(directory .. "/" .. path .. "/" .. list[i]) then
			list[i] = list[i] .. "/"
		end
	end
	return list
end
function obj.isReadOnly() -- Returns whether the file system is read-only.
	--STUB
	cprint("filesystem.isReadOnly")
	return readonly
end
function obj.makeDirectory(path) -- Creates a directory at the specified absolute path in the file system. Creates parent directories, if necessary.
	--STUB
	cprint("filesystem.makeDirectory", path)
end
function obj.isDirectory(path) -- Returns whether the object at the specified absolute path in the file system is a directory.
	--STUB
	cprint("filesystem.isDirectory", path)
	return love.filesystem.isDirectory(directory .. "/" .. path)
end

local cec = {}

return obj,cec
