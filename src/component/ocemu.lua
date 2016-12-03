-- ocemu component

component.connect("filesystem",gen_uuid(),nil,"customlua/ocemu",true)

local components = settings.components

local function cleanName(name)
	if name:find("/", nil, true) then
		return (name:match(".*/(.+)"))
	end
	return name
end

local mai = {}
local obj = {}

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

function obj.disconnect(address)
	cprint("ocemu.disconnect", address)
	compCheckArg(1,address,"string")
	return component.disconnect(address)
end

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
		component.connect("filesystem", address, nil, "loot/"..name, true)
		components[#components+1]={"filesystem", address, nil, "loot/"..name, true}
		config.save()
	end
	return true
end

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

function obj.biglist()
	machine.biglistgen=true
end

function obj.log(...)
	print(...)
end

return obj,nil,mai
