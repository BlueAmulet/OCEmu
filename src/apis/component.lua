local env = ...

local r = math.random
function gen_uuid()
	return string.format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
	r(0,255),r(0,255),r(0,255),r(0,255),
	r(0,255),r(0,255),
	r(64,79),r(0,255),
	r(128,191),r(0,255),
	r(0,255),r(0,255),r(0,255),r(0,255),r(0,255),r(0,255))
end

local proxylist = {}
local slotlist = {}
local emuicc = {}
local doclist = {}

-- Load components
local components = conf.components
for k,v in pairs(components) do
	local address
	if type(v[2]) == "string" then
		address = v[2]
	else
		math.randomseed(type(v[2]) == "number" and v[2] or k)
		address = gen_uuid()
	end
	v[2] = address
	local proxy, cec, doc = love.filesystem.load("component/" .. v[1] .. ".lua")(table.unpack(v,2))
	proxy.address = address
	proxy.type = v[1]
	proxylist[address] = proxy
	emuicc[address] = cec
	doclist[address] = doc
	slotlist[address] = v[3]
end

component = {}

function component.exists(address)
	checkArg(1,address,"string")
	if proxylist[address] ~= nil then
		return proxylist[address].type
	end
end
function component.list(filter, exact)
	checkArg(1,filter,"string","nil")
	local data = {}
	local tbl = {}
	for k,v in pairs(proxylist) do
		if filter == nil or (exact and v.type == filter) or (not exact and v.type:find(filter, nil, true)) then
			data[#data + 1] = k
			data[#data + 1] = v.type
			tbl[k] = v.type
		end
	end
	local place = 1
	return setmetatable(tbl,{__call = function()
		local addr,type = data[place], data[place + 1]
		place = place + 2
		return addr,type
	end})
end
function component.invoke(address, method, ...)
	checkArg(1,address,"string")
	checkArg(2,method,"string")
	if proxylist[address] ~= nil then
		if proxylist[address][method] == nil then
			error("no such method",2)
		end
		return proxylist[address][method](...)
	end
end
function component.cecinvoke(address, method, ...)
	checkArg(1,address,"string")
	checkArg(2,method,"string")
	if emuicc[address] ~= nil then
		if emuicc[address][method] == nil then
			error("no such method",2)
		end
		return emuicc[address][method](...)
	end
end

env.component = {list = component.list}

function env.component.type(address)
	checkArg(1,address,"string")
	if proxylist[address] ~= nil then
		return proxylist[address].type
	end
	return nil, "no such component"
end

function env.component.slot(address)
	checkArg(1,address,"string")
	if proxylist[address] ~= nil then
		return slotlist[address] or -1
	end
	return nil, "no such component"
end

function env.component.methods(address)
	checkArg(1,address,"string")
	if proxylist[address] ~= nil then
		local methods = {}
		for k,v in pairs(proxylist[address]) do
			if type(v) == "function" then
				methods[k] = {direct=true} -- TODO: getter, setter?
			end
		end
		return methods
	end
end

function env.component.invoke(address, method, ...)
	checkArg(1,address,"string")
	checkArg(2,method,"string")
	if proxylist[address] ~= nil then
		if proxylist[address][method] == nil then
			error("no such method",2)
		end
		return true, proxylist[address][method](...)
	end
end

function env.component.doc(address, method)
	checkArg(1,address,"string")
	checkArg(2,method,"string")
	if proxylist[address] ~= nil then
		if proxylist[address][method] == nil then
			error("no such method",2)
		end
		if doclist[address] ~= nil then
			return doclist[address][method]
		end
		return nil
	end
end
