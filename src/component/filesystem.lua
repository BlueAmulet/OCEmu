local address, _, directory, label, readonly, speed = ...
compCheckArg(1,directory,"string","nil")
compCheckArg(2,label,"string","nil")
compCheckArg(3,readonly,"boolean")
compCheckArg(4,speed,"number")

local istmpfs = false -- used to simulate differences between tmpfs and drives

if directory == nil then
	directory = elsa.filesystem.getSaveDirectory() .. "/" .. address
elseif directory == "tmpfs" then
	directory = elsa.filesystem.getSaveDirectory() .. "/tmpfs"
	computer.setTempAddress(address)
	istmpfs = true
end

if not elsa.filesystem.exists(directory) then
	elsa.filesystem.createDirectory(directory)
end

local vague = settings.vagueErrors

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

local readCosts = {1/1, 1/4, 1/7, 1/10, 1/13, 1/15}
local seekCosts = {1/1, 1/4, 1/7, 1/10, 1/13, 1/15}
local writeCosts = {1/1, 1/2, 1/3, 1/4, 1/5, 1/6}

-- filesystem component
local mai = {}
local obj = {}

mai.read = {direct = true, limit = 15, doc = "function(handle:number, count:number):string or nil -- Reads up to the specified amount of data from an open file descriptor with the specified handle. Returns nil when EOF is reached."}
function obj.read(handle, count)
	--TODO
	cprint("filesystem.read", handle, count)
	if not machine.consumeCallBudget(readCosts[speed]) then return end
	compCheckArg(1,handle,"number")
	compCheckArg(2,count,"number")
	if handles[handle] == nil or handles[handle][2] ~= "r" then
		return nil, "bad file descriptor"
	end
	count = math.min(math.max(count, 0), settings.maxReadBuffer)
	if count == math.huge then count = "*a" end
	local ret = { handles[handle][1]:read(count) }
	if ret[1] == "" and count ~= 0 then ret[1] = nil end
	return table.unpack(ret)
end

mai.lastModified = {direct = true, doc = "function(path:string):number -- Returns the (real world) timestamp of when the object at the specified absolute path in the file system was modified."}
function obj.lastModified(path)
	cprint("filesystem.lastModified", path)
	compCheckArg(1,path,"string")
	path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
	return elsa.filesystem.getLastModified(directory .. "/" .. path) or 0
end

mai.spaceUsed = {direct = true, doc = "function():number -- The currently used capacity of the file system, in bytes."}
function obj.spaceUsed()
	--STUB
	cprint("filesystem.spaceUsed")
	return 0
end

mai.rename = {doc = "function(from:string, to:string):boolean -- Renames/moves an object from the first specified absolute path in the file system to the second."}
function obj.rename(from, to)
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

mai.close = {direct = true, doc = "function(handle:number) -- Closes an open file descriptor with the specified handle."}
function obj.close(handle)
	cprint("filesystem.close", handle)
	compCheckArg(1,handle,"number")
	if handles[handle] == nil then
		return nil, "bad file descriptor"
	end
	handles[handle][1]:close()
	handles[handle] = nil
end

mai.write = {direct = true, doc = "function(handle:number, value:string):boolean -- Writes the specified data to an open file descriptor with the specified handle."}
function obj.write(handle, value)
	cprint("filesystem.write", handle, value)
	if not machine.consumeCallBudget(writeCosts[speed]) then return end
	compCheckArg(1,handle,"number")
	compCheckArg(2,value,"string")
	if handles[handle] == nil or (handles[handle][2] ~= "w" and handles[handle][2] ~= "a") then
		return nil, "bad file descriptor"
	end
	handles[handle][1]:write(value)
	return true
end

mai.remove = {doc = "function(path:string):boolean -- Removes the object at the specified absolute path in the file system."}
function obj.remove(path)
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

mai.size = {direct = true, doc = "function(path:string):number -- Returns the size of the object at the specified absolute path in the file system."}
function obj.size(path)
	cprint("filesystem.size", path)
	compCheckArg(1,path,"string")
	path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
	return elsa.filesystem.getSize(directory .. "/" .. path) or 0
end

mai.seek = {direct = true, doc = "function(handle:number, whence:string, offset:number):number -- Seeks in an open file descriptor with the specified handle. Returns the new pointer position."}
function obj.seek(handle, whence, offset)
	--TODO
	cprint("filesystem.seek", handle, whence, offset)
	if not machine.consumeCallBudget(seekCosts[speed]) then return end
	compCheckArg(1,handle,"number")
	compCheckArg(2,whence,"string")
	compCheckArg(3,offset,"number")
	if handles[handle] == nil then
		return nil, "bad file descriptor"
	end
	return handles[handle][1]:seek(whence, offset)
end

mai.spaceTotal = {direct = true, doc = "function():number -- The overall capacity of the file system, in bytes."}
function obj.spaceTotal()
	--STUB
	cprint("filesystem.spaceTotal")
	return math.huge
end

mai.getLabel = {direct = true, doc = "function():string -- Get the current label of the file system."}
function obj.getLabel()
	cprint("filesystem.getLabel")
	return label
end

mai.setLabel = {doc = "function(value:string):string -- Sets the label of the file system. Returns the new value, which may be truncated."}
function obj.setLabel(value)
	--TODO: treat functions as nil
	cprint("filesystem.setLabel", value)
	compCheckArg(1,value,"string")
	if readonly or istmpfs then
		error("label is read only", 0)
	end
	value = value:sub(1,16)
	if label ~= value then
		label = value
		--TODO: set label in config a bit more efficiently.
		for _, v in pairs(settings.components) do
			if v[1] == "filesystem" and v[2] == address then
				v[5] = label
			end
		end
		config.save()
	end
end

mai.open = {direct = true, limit = 4, doc = "function(path:string[, mode:string='r']):number -- Opens a new file descriptor and returns its handle."}
function obj.open(path, mode)
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
		error("unsupported mode", 0)
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

mai.exists = {direct = true, doc = "function(path:string):boolean -- Returns whether an object exists at the specified absolute path in the file system."}
function obj.exists(path)
	cprint("filesystem.exists", path)
	compCheckArg(1,path,"string")
	path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
	return elsa.filesystem.exists(directory .. "/" .. path)
end

mai.list = {doc = "function(path:string):table -- Returns a list of names of objects in the directory at the specified absolute path in the file system."}
function obj.list(path)
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

mai.isReadOnly = {direct = true, doc = "function():boolean -- Returns whether the file system is read-only."}
function obj.isReadOnly()
	cprint("filesystem.isReadOnly")
	return readonly
end

mai.makeDirectory = {direct = true, doc = "function(path:string):boolean -- Creates a directory at the specified absolute path in the file system. Creates parent directories, if necessary."}
function obj.makeDirectory(path)
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

mai.isDirectory = {direct = true, doc = "function(path:string):boolean -- Returns whether the object at the specified absolute path in the file system is a directory."}
function obj.isDirectory(path)
	cprint("filesystem.isDirectory", path)
	compCheckArg(1,path,"string")
	path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
	return elsa.filesystem.isDirectory(directory .. "/" .. path)
end

return obj,nil,mai
