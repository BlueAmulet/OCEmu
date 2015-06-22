local component = require("component")
local kbd = require("keyboard")
local event = require("event")
local term = require("term")

if not component.isAvailable("ocemu") then
	io.stderr:write("This program requires OCEmu to run.")
	return
end

local ocemu = component.ocemu
local gpu = component.gpu
local keys = kbd.keys

local gpuW,gpuH = gpu.getResolution()

gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)

local function setTitle(title)
	gpu.set((gpuW-#title)/2,1,title)
end

local function setStatus(status)
	gpu.fill(1,gpuH,gpuW,1," ")
	gpu.set((gpuW-#status)/2,gpuH,status)
end

local function componentConfig()
	setTitle("Component Configuration Utility")
	local list = {}
	for address, kind in component.list() do
		list[#list+1] = {address, kind}
	end
	table.sort(list, function(a, b) return a[1] < b[1] end)
	local listX = 1
	
	local function drawList()
		gpu.fill(1,3,gpuW,gpuH-3," ")
		for i = 1,#list do
			gpu.set(4,i+2,string.format("%s - %s",list[i][1],list[i][2]))
		end
		gpu.set(2,listX+2,"▶")
	end
	local function prompt(msg)
		gpu.fill(1,gpuH-3,gpuW,1," ")
		term.setCursor(1,gpuH-3)
		io.stdout:write(msg)
		return term.read(nil, false):gsub("[\r\n]","")
	end
	drawList()
	
	while true do
		local evnt = table.pack(event.pull())
		if evnt[1] == "key_down" then
			if evnt[4] == keys.up and listX > 1 then
				gpu.set(2,listX+2," ")
				listX = listX - 1
				gpu.set(2,listX+2,"▶")
			elseif evnt[4] == keys.down and listX < #list then
				gpu.set(2,listX+2," ")
				listX = listX + 1
				gpu.set(2,listX+2,"▶")
			elseif evnt[4] == keys.delete then
				local ok, err = ocemu.disconnect(list[listX][1])
				if ok then
					table.remove(list, listX)
					listX = math.min(listX,#list)
					drawList()
				else
					setStatus(err or "unknown error")
				end
			elseif evnt[4] == keys.insert then
				setStatus("")
				local kind = prompt("Component type: ")
				local address = prompt("Component address: ")
				local slot = prompt("Component slot: ")
				local args = prompt("Component arguments: ")
				
				local bad = false
				if kind == "" or kind == nil then
					bad = true
					setStatus("Invalid type")
				end
				if address == "" or address == nil then
					address = nil
				elseif tonumber(address) ~= nil then
					address = tonumber(address)
				elseif address ~= address:gsub("[^%x-]","") or address:match("........%-....%-4...%-[89abAB]...%-............") == nil then
					bad = true
					setStatus("Invalid address")
				end
				if slot == "" or slot == nil then
					slot = nil
				elseif tonumber(slot) ~= nil then
					slot = tonumber(slot)
				else
					bad = true
					setStatus("Invalid slot")
				end
				if not bad then
					local fn, err = load("return " .. args,"=arguments","t",{})
					if not fn then
						setStatus(err)
					else
						local args = table.pack(pcall(fn))
						if not args[1] then
							setStatus(args[2])
						else
							local rok, ok, err = pcall(ocemu.connect, kind, address, slot, table.unpack(args, 2))
							if not rok then
								if ok:match("^.-:.-: .*") then
									ok = ok:match("^.-:.-: (.*)")
								end
								setStatus(ok)
							elseif not ok then
								setStatus(err)
							else
								list = {}
								for address, kind in component.list() do
									list[#list+1] = {address, kind}
								end
								table.sort(list, function(a, b) return a[1] < b[1] end)
							end
						end
					end
				end
				drawList()
			elseif evnt[3] == string.byte("q") then
				return
			end
		end
	end
end

local menu = {
	{"Configure Components",componentConfig},
	{"Exit",os.exit}
}
local menuX = 1

local function drawMenu()
	gpu.fill(1,1,gpuW,gpuH," ")
	setTitle("OCEmu Setup Utility")
	for i = 1,#menu do
		gpu.set(4,i+2,menu[i][1])
	end
	gpu.set(2,menuX+2,"▶")
end
drawMenu()

while true do
	local evnt = table.pack(event.pull())
	if evnt[1] == "key_down" then
		if evnt[4] == keys.up and menuX > 1 then
			gpu.set(2,menuX+2," ")
			menuX = menuX - 1
			gpu.set(2,menuX+2,"▶")
		elseif evnt[4] == keys.down and menuX < #menu then
			gpu.set(2,menuX+2," ")
			menuX = menuX + 1
			gpu.set(2,menuX+2,"▶")
		elseif evnt[4] == keys.enter then
			gpu.fill(1,1,gpuW,gpuH," ")
			menu[menuX][2]()
			drawMenu()
		end
	end
end
