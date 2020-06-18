-- ocemu component

-- TODO: Remove this eventually
component.connect("filesystem", gen_uuid(), -1, "customlua/ocemu", "ocemu", true, 5)

local components = settings.components

local function cleanName(name)
	if name:find("/", nil, true) then
		return (name:match(".*/(.+)"))
	end
	return name
end

local mai = {}
local obj = {}

mai.connect = {direct = true, doc = "function(kind:string, address:string or number or nil, slot:number or nil, ...):boolean -- Attach a component to the emulator."}
function obj.connect(kind, address, slot, ...)
	cprint("ocemu.connect", kind, address, slot, ...)
	compCheckArg(1,kind,"string")
	compCheckArg(2,address,"string","number","nil")
	compCheckArg(3,slot,"number","nil")
	if address == nil then
		if elsa.SDL then
			math.randomseed(elsa.SDL.getTicks())
		else
			math.randomseed(os.clock()*1000000)
		end
		address=gen_uuid()
	end
	return component.connect(kind, address, slot, ...)
end

mai.disconnect = {direct = true, doc = "function(address:string):boolean -- Remove a component from the emulator."}
function obj.disconnect(address)
	cprint("ocemu.disconnect", address)
	compCheckArg(1,address,"string")
	return component.disconnect(address)
end

mai.lootlist = {direct = true, doc = "function():table -- Get a list of loot disks and disk information."}
function obj.lootlist()
	cprint("ocemu.lootlist")
	local info={}
	for line in io.lines("loot/loot.properties") do
		line = string_trim(line)
		if line ~= "" and line:sub(1, 1) ~= "#" then
			local path, name, color=line:match("(.-)=(.+):%d+:(.+)")
			info[path]={name,color}
		end
	end
	local list=elsa.filesystem.getDirectoryItems("loot")
	local dirs={}
	for i=1, #list do
		local path=list[i]
		if elsa.filesystem.isDirectory("loot/"..path) then
			dirs[#dirs+1]={path, info[path] and info[path][1] or "(No Name)", info[path] and info[path][2] or "dyeGray"}
		end
	end
	table.sort(dirs, function(a, b) return a[1]<b[1] end)
	dirs.n=#dirs
	return dirs
end

mai.lootinsert = {direct = true, doc = "function(name:string):boolean or nil, string -- Insert a loot disk into the computer."}
function obj.lootinsert(name)
	cprint("ocemu.lootinsert", name)
	compCheckArg(1,name,"string")
	name=cleanName(name)
	if not elsa.filesystem.exists("loot/"..name) then
		return nil, "no such loot"
	end
	local attached=false
	for _, v in pairs(components) do
		if v[1]=="filesystem" and v[4]=="loot/"..name then
			attached=true
			break
		end
	end
	if not attached then
		local address=gen_uuid()
		component.connect("filesystem", address, -1, "loot/"..name, name, true, 1)
		components[#components+1]={"filesystem", address, -1, "loot/"..name, name, true, 1}
		config.save()
	end
	return true
end

mai.lootremove = {direct = true, doc = "function(name:string):boolean or nil, string -- Remove a loot disk from the computer."}
function obj.lootremove(name)
	cprint("ocemu.lootremove", name)
	compCheckArg(1,name,"string")
	if not elsa.filesystem.exists("loot/"..name) then
		return nil, "no such loot"
	end
	local offset=0
	for i=1,#components do
		local v=components[i-offset]
		if v[1]=="filesystem" and v[4]=="loot/"..name then
			component.disconnect(v[2])
			table.remove(components, i-offset)
			offset=offset+1
		end
	end
	if offset ~= 0 then
		config.save()
	end
	return true
end

mai.lootattached = {direct = true, doc = "function(name:string):boolean or nil, string -- Check if a loot disk is inserted in the computer."}
function obj.lootattached(name)
	cprint("ocemu.lootattached", name)
	compCheckArg(1,name,"string")
	if not elsa.filesystem.exists("loot/"..name) then
		return nil, "no such loot"
	end
	for _, v in pairs(components) do
		if v[1]=="filesystem" and v[4]=="loot/"..name then
			return true, v[2]
		end
	end
	return false
end

mai.biglist = {direct = true, doc = "function() -- Generate a giant useless list of lua information from the computer."}
function obj.biglist()
	machine.biglistgen=true
end

mai.log = {direct = true, doc = "function(...) -- Output a message to the emulator's stdout."}
function obj.log(...)
	print(...)
end

return obj,nil,mai
