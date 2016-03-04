local address, _, directory, readonly = ...
compCheckArg(1,directory,"string","nil")
compCheckArg(2,readonly,"boolean")

if directory == nil then
	directory = elsa.filesystem.getSaveDirectory() .. "/" .. address
elseif directory == "tmpfs" then
	directory = elsa.filesystem.getSaveDirectory() .. "/tmpfs"
	computer.setTempAddress(address)
end

if not elsa.filesystem.exists(directory) then
	elsa.filesystem.createDirectory(directory)
end

local vague = settings.vagueErrors

local label = ("/" .. directory):match(".*/(.+)")
if label == address then
	label = nil
end
local handles = {}

local function cleanPath(path)
	local path = path:gsub("\\", "/")

	local tPath = {}
	for part in path:gmatch("[^/]+") do
   		if part ~= "" and part ~= "." then
   			if part == ".." and #tPath > 0 and tPath[#tPath] ~= ".." then
   				table.remove(tPath)
   			else
   				table.insert(tPath, part)
   			end
   		end
	end
	if #tPath == 0 then
		return "."
	end
	return table.concat(tPath, "/")
end

-- filesystem component
local obj = {}

function obj.read(handle, count) -- Reads up to the specified amount of data from an open file descriptor with the specified handle. Returns nil when EOF is reached.
	--TODO
	cprint("filesystem.read", handle, count)
	compCheckArg(1,handle,"number")
	compCheckArg(2,count,"number")
	if handles[handle] == nil or handles[handle][2] ~= "r" then
		return nil, "bad file descriptor"
	end
	count = math.max(count,0)
	if count == math.huge then count = "*a" end
	local ret = { handles[handle][1]:read(count) }
	if ret[1] == "" and count ~= 0 then ret[1] = nil end
	return table.unpack(ret)
end
function obj.lastModified(path) -- Returns the (real world) timestamp of when the object at the specified absolute path in the file system was modified.
	cprint("filesystem.lastModified", path)
	compCheckArg(1,path,"string")
	path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
	return elsa.filesystem.getLastModified(directory .. "/" .. path) or 0
end
function obj.spaceUsed() -- The currently used capacity of the file system, in bytes.
	--STUB
	cprint("filesystem.spaceUsed")
	return 0
end
function obj.rename(from, to) -- Renames/moves an object from the first specified absolute path in the file system to the second.
	cprint("filesystem.rename", from, to)
	compCheckArg(1,from,"string")
	local ofrom = from
	from = cleanPath(from)
	if from == ".." or from:sub(1,3) == "../" then
		return nil,"file not found"
	end
	compCheckArg(2,to,"string")
	to = cleanPath(to)
	if to == ".." or to:sub(1,3) == "../" then
		return nil,"file not found"
	end
	if readonly then
		return false
	end
	local ok, err = os.rename(directory .. "/" .. from, directory .. "/" .. to)
	if ok then
		return true
	elseif vague then
		return nil, ofrom
	else
		return nil, err
	end
end
function obj.close(handle) -- Closes an open file descriptor with the specified handle.
	cprint("filesystem.close", handle)
	compCheckArg(1,handle,"number")
	if handles[handle] == nil then
		return nil, "bad file descriptor"
	end
	handles[handle][1]:close()
	handles[handle] = nil
end
function obj.write(handle, value) -- Writes the specified data to an open file descriptor with the specified handle.
	cprint("filesystem.write", handle, value)
	compCheckArg(1,handle,"number")
	compCheckArg(2,value,"string")
	if handles[handle] == nil or (handles[handle][2] ~= "w" and handles[handle][2] ~= "a") then
		return nil, "bad file descriptor"
	end
	handles[handle][1]:write(value)
	return true
end
function obj.remove(path) -- Removes the object at the specified absolute path in the file system.
	cprint("filesystem.remove", path)
	compCheckArg(1,path,"string")
	path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
	if readonly then
		return false
	end
	return elsa.filesystem.remove(directory .. "/" .. path)
end
function obj.size(path) -- Returns the size of the object at the specified absolute path in the file system.
	cprint("filesystem.size", path)
	compCheckArg(1,path,"string")
	path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
	return elsa.filesystem.getSize(directory .. "/" .. path) or 0
end
function obj.seek(handle, whence, offset) -- Seeks in an open file descriptor with the specified handle. Returns the new pointer position.
	--TODO
	cprint("filesystem.seek", handle, whence, offset)
	compCheckArg(1,handle,"number")
	compCheckArg(2,whence,"string")
	compCheckArg(3,offset,"number")
	if handles[handle] == nil then
		return nil, "bad file descriptor"
	end
	return handles[handle][1]:seek(whence, offset)
end
function obj.spaceTotal() -- The overall capacity of the file system, in bytes.
	--STUB
	cprint("filesystem.spaceTotal")
	return math.huge
end
function obj.getLabel() -- Get the current label of the file system.
	cprint("filesystem.getLabel")
	return label
end
function obj.setLabel(value) -- Sets the label of the file system. Returns the new value, which may be truncated.
	--TODO: treat functions as nil
	cprint("filesystem.setLabel", value)
	compCheckArg(1,value,"string")
	if readonly or directory:sub(-6) == "/tmpfs" then
		error("label is read only",3)
	end
	label = value:sub(1,16)
end
function obj.open(path, mode) -- Opens a new file descriptor and returns its handle.
	cprint("filesystem.open", path, mode)
	if mode == nil then mode = "r" end
	compCheckArg(1,path,"string")
	compCheckArg(2,mode,"string")
	local opath = path
	path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil, (vague and opath or "file not found")
	end
	if mode ~= "r" and mode ~= "rb" and mode ~= "w" and mode ~= "wb" and mode ~= "a" and mode ~= "ab" then
		error("unsupported mode",3)
	end
	if (mode == "r" or mode == "rb") and not elsa.filesystem.exists(directory .. "/" .. path) then
		return nil, (vague and opath or "file not found")
	elseif not (mode == "r" or mode == "rb") and readonly then
		return nil, (vague and opath or "filesystem is read only")
	end
	local file, err = elsa.filesystem.newFile(directory .. "/" .. path, mode:sub(1,1))
	if not file then return nil, (vague and opath or err) end
	while true do
		local rnddescrpt = math.random(1000000000,9999999999)
		if handles[rnddescrpt] == nil then
			handles[rnddescrpt] = {file,mode:sub(1,1)}
			return rnddescrpt
		end
	end
end
function obj.exists(path) -- Returns whether an object exists at the specified absolute path in the file system.
	cprint("filesystem.exists", path)
	compCheckArg(1,path,"string")
	path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
	return elsa.filesystem.exists(directory .. "/" .. path)
end
function obj.list(path) -- Returns a list of names of objects in the directory at the specified absolute path in the file system.
	--TODO
	cprint("filesystem.list", path)
	compCheckArg(1,path,"string")
	path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
	if not elsa.filesystem.exists(directory .. "/" .. path) then
		return nil, "no such file or directory"
	elseif not elsa.filesystem.isDirectory(directory .. "/" .. path) then
		local entry = (directory .. "/" .. path):match(".*/(.+)")
		return {entry}
	end
	local list = elsa.filesystem.getDirectoryItems(directory .. "/" .. path)
	for i = 1,#list do
		if elsa.filesystem.isDirectory(directory .. "/" .. path .. "/" .. list[i]) then
			list[i] = list[i] .. "/"
		end
	end
	list.n = #list
	return list
end
function obj.isReadOnly() -- Returns whether the file system is read-only.
	cprint("filesystem.isReadOnly")
	return readonly
end
function obj.makeDirectory(path) -- Creates a directory at the specified absolute path in the file system. Creates parent directories, if necessary.
	cprint("filesystem.makeDirectory", path)
	compCheckArg(1,path,"string")
	path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
	if elsa.filesystem.exists(directory .. "/" .. path) or readonly then
		return false
	end
	return elsa.filesystem.createDirectory(directory .. "/" .. path)
end
function obj.isDirectory(path) -- Returns whether the object at the specified absolute path in the file system is a directory.
	cprint("filesystem.isDirectory", path)
	compCheckArg(1,path,"string")
	path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
	return elsa.filesystem.isDirectory(directory .. "/" .. path)
end

local cec = {}

local doc = {
	["read"]="function(handle:number, count:number):string or nil -- Reads up to the specified amount of data from an open file descriptor with the specified handle. Returns nil when EOF is reached.",
	["lastModified"]="function(path:string):number -- Returns the (real world) timestamp of when the object at the specified absolute path in the file system was modified.",
	["spaceUsed"]="function():number -- The currently used capacity of the file system, in bytes.",
	["rename"]="function(from:string, to:string):boolean -- Renames/moves an object from the first specified absolute path in the file system to the second.",
	["close"]="function(handle:number) -- Closes an open file descriptor with the specified handle.",
	["write"]="function(handle:number, value:string):boolean -- Writes the specified data to an open file descriptor with the specified handle.",
	["remove"]="function(path:string):boolean -- Removes the object at the specified absolute path in the file system.",
	["size"]="function(path:string):number -- Returns the size of the object at the specified absolute path in the file system.",
	["seek"]="function(handle:number, whence:string, offset:number):number -- Seeks in an open file descriptor with the specified handle. Returns the new pointer position.",
	["spaceTotal"]="function():number -- The overall capacity of the file system, in bytes.",
	["getLabel"]="function():string -- Get the current label of the file system.",
	["setLabel"]="function(value:string):string -- Sets the label of the file system. Returns the new value, which may be truncated.",
	["open"]="function(path:string[, mode:string='r']):number -- Opens a new file descriptor and returns its handle.",
	["exists"]="function(path:string):boolean -- Returns whether an object exists at the specified absolute path in the file system.",
	["list"]="function(path:string):table -- Returns a list of names of objects in the directory at the specified absolute path in the file system.",
	["isReadOnly"]="function():boolean -- Returns whether the file system is read-only.",
	["makeDirectory"]="function(path:string):boolean -- Creates a directory at the specified absolute path in the file system. Creates parent directories, if necessary.",
	["isDirectory"]="function(path:string):boolean -- Returns whether the object at the specified absolute path in the file system is a directory.",
}

return obj,cec,doc
