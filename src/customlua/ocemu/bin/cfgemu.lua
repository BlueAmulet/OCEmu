local component = require("component")
local kbd = require("keyboard")
local event = require("event")
local term = require("term")
local unicode = require("unicode")
local colors = require("colors")

if not component.isAvailable("ocemu") then
	io.stderr:write("This program requires OCEmu to run.")
	return
end

local ocemu = component.ocemu
local gpu = component.gpu
local keys = kbd.keys

local floppy = {
"\226\150\137\238\161\129\238\161\129\238\161\129\238\161\129\238\132\132",
"\226\150\137\238\161\129\238\161\129\238\161\129\238\161\129\238\132\132",
"\238\132\163\226\150\140\226\150\174\32\226\150\144\226\150\136"
}
local floppyTop = "\226\161\164\226\160\164\226\160\164\226\160\164\226\160\164\226\160\164\226\160\164\226\162\164"
local floppyBott = "\226\160\147\226\160\146\226\160\146\226\160\146\226\160\146\226\160\146\226\160\146\226\160\154"
local floppyLeft = unicode.char(0x258C)
local floppyRight = unicode.char(0x2590)
local floppyPal = {[0]=0xFFFFFF,0xFFCC33,0xCC66CC,0x6699FF,0xFFFF33,0x33CC33,0xFF6699,0x333333,0xCCCCCC,0x336699,0x9933CC,0x333399,0x663300,0x336600,0xFF3333,0x000000}

local gpuW,gpuH = gpu.getResolution()
local gpuColor = gpu.getDepth()>1

gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)

local function setTitle(title)
	gpu.set((gpuW-#title)/2,1,title)
end

local function setStatus(status)
	gpu.fill(1,gpuH,gpuW,1," ")
	gpu.set((gpuW-#status)/2,gpuH,status)
end

local function floppySelect()
	setTitle("Loot Disk Configuration Utility")
	local list = ocemu.lootlist()
	local listpos = 1
	local cx=math.floor(gpuW/2)
	local cy=math.floor(gpuH/2)-2
	local fcount=math.floor(gpuW/24)
	gpu.set(cx-1, cy-3, "\226\151\165\226\151\164")

	local function drawFloppy(ox, oy, name, color)
		if gpuColor then
			gpu.setForeground(floppyPal[colors[color:sub(4):lower()] or colors.gray])
		end
		for y=0,2 do
			gpu.set(ox-3, oy+y, floppy[y+1])
		end
		if gpuColor then
			gpu.setForeground(0xFFFFFF)
		end
		if ocemu.lootattached(name) then
			gpu.set(ox-4, oy-1, floppyTop)
			gpu.set(ox-4, oy+3, floppyBott)
			gpu.fill(ox-4, oy, 1, 3, floppyLeft)
			gpu.fill(ox+3, oy, 1, 3, floppyRight)
		end
		gpu.set(ox-(#name/2), oy+4, name)
	end
	local function drawLoot()
		gpu.fill(1, cy-2, gpuW, 7, " ")
		for i=-fcount, fcount do
			local disk = list[listpos+i]
			if disk then
				drawFloppy(cx+i*12, cy-(i==0 and 1 or 0), disk[1], disk[3])
			end
		end
		setStatus(list[listpos][2])
	end
	drawLoot()

	while true do
		local evnt = table.pack(event.pull())
		if evnt[1] == "key_down" then
			if evnt[4] == keys.left and listpos > 1 then
				listpos = listpos - 1
				drawLoot()
			elseif evnt[4] == keys.right and listpos < #list then
				listpos = listpos + 1
				drawLoot()
			elseif evnt[4] == keys.enter then
				local path = list[listpos][1]
				if ocemu.lootattached(path) then
					ocemu.lootremove(path)
					drawLoot()
				else
					ocemu.lootinsert(path)
					drawLoot()
				end
			elseif evnt[3] == string.byte("q") then
				return
			end
		end
	end
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
	{"Add and Remove Floppies",floppySelect},
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
	setStatus("Press Q to quit")
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
		elseif evnt[3] == string.byte("q") then
			return
		end
	end
end
