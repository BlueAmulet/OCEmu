-- Configuration api for OCEmu
local _config
local comments = {
[1]="OCEmu configuration. Designed to mimic HOCON syntax, but is not exactly HOCON syntax.",
["client"]="Client side settings, presentation and performance related stuff.",
["client.monochromeColor"]="The color of monochrome text (i.e. displayed when in 1-bit color depth, e.g. tier one screens / GPUs, or higher tier set to 1-bit color depth). Defaults to white, feel free to make it some other color, tho!",
["computer"]="Computer related settings, concerns server performance and security.",
["computer.lua"]="Settings specific to the Lua architecture.",
["computer.lua.allowBytecode"]="Whether to allow loading precompiled bytecode via Lua's `load` function, or related functions (`loadfile`, `dofile`). Enable this only if you absolutely trust all users on your server and all Lua code you run. This can be a MASSIVE SECURITY RISK, since precompiled code can easily be used for exploits, running arbitrary code on the real server! I cannot stress this enough: only enable this is you know what you're doing.",
["computer.lua.allowGC"]="Whether to allow user defined __gc callbacks, i.e. __gc callbacks defined *inside* the sandbox. Since garbage collection callbacks are not sandboxed (hooks are disabled while they run), this is not recommended.",
["computer.timeout"]="The time in seconds a program may run without yielding before it is forcibly aborted. This is used to avoid stupidly written or malicious programs blocking other computers by locking down the executor threads. Note that changing this won't have any effect on computers that are already running - they'll have to be rebooted for this to take effect.",
["emulator"]="Emulator related settings. Components, accuracy, and debugging.",
["emulator.components"]="Default components available to the computer.",
["emulator.debug"]="Whether to enable the emulator's extremely verbose logging.",
["emulator.vague"]="Whether to return vague error messages like OpenComputers.",
["internet.enableHttp"]="Whether to allow HTTP requests via internet cards. When enabled, the `request` method on internet card components becomes available.",
["internet.enableTcp"]="Whether to allow TCP connections via internet cards. When enabled, the `connect` method on internet card components becomes available.",
["misc"]="Other settings that you might find useful to tweak.",
["misc.maxNetworkPacketSize"]="The maximum size of network packets to allow sending via network cards. This has *nothing to do* with real network traffic, it's just a limit for the network cards, mostly to reduce the chance of computer with a lot of RAM killing those with less by sending huge packets. This does not apply to HTTP traffic.",
["misc.maxWirelessRange"]="The maximum distance a wireless message can be sent. In other words, this is the maximum signal strength a wireless network card supports. This is used to limit the search range in which to check for modems, which may or may not lead to performance issues for ridiculous ranges - like, you know, more than the loaded area. See also: `wirelessCostPerRange`.",
}

local function writeComment(text,file,size)
	file:write(string.rep(" ",size) .. "--")
	local line = ""
	for word in text:gmatch("[%S]+") do
		if #line + #word + 1 > 78-size then
			line = ""
			file:write("\n" .. string.rep(" ",size) .. "--")
		end
		file:write((line == "" and "" or " ") .. word)
		line = line .. (line == "" and "" or " ") .. word
	end
	file:write("\n")
end

local function tlen(t)
	local n = -math.huge
	for k in pairs(t) do
		if type(k) == "number" and k >= n then
			n = k
		end
	end
	return n
end

local serialize
function serialize(tbl,key,path,file,size)
	file:write(string.rep(" ",size-2) .. key .. " {\n")
	local keys = {}
	for k,v in pairs(tbl) do
		keys[#keys+1] = k
	end
	table.sort(keys)
	for i = 1,#keys do
		local k = keys[i]
		local v = tbl[k]
		local spath = path .. (path == "" and "" or ".") .. k
		file:write("\n")
		if comments[spath] then
			writeComment(comments[spath],file,size)
		end
		if spath == "emulator.components" then
			file:write(string.rep(" ",size) .. k .. " {\n\n")
			for i = 1,#v do
				local comp = v[i]
				file:write(string.rep(" ",size+2) .. "{")
				comp.n=tlen(comp)
				for i = 1,comp.n do
					if type(comp[i]) == "string" then
						file:write(string.format("%q",comp[i]))
					else
						file:write(tostring(comp[i]))
					end
					if i < comp.n then
						file:write(", ")
					end
				end
				file:write("}")
				if i < #v then
					file:write(",")
				end
				file:write("\n")
			end
			file:write(string.rep(" ",size) .. "}\n")
		elseif type(v) == "table" then
			local list = true
			for k,l in pairs(v) do
				if type(k) ~= "number" or type(l) ~= "number" then
					list = false
					break
				end
			end
			if list then
				file:write(string.rep(" ",size) .. k .. "=[\n")
				for i = 1,#v do
					file:write(string.rep(" ",size+2) .. v[i] .. (i < #v and "," or "") .. "\n")
				end
				file:write(string.rep(" ",size) .. "]\n")
			else
				serialize(v,k,spath,file,size+2)
			end
		elseif type(v) == "string" then
			file:write(string.rep(" ",size) .. k .. "=" .. string.format("%q",v) .. "\n")
		else
			file:write(string.rep(" ",size) .. k .. "=" .. tostring(v) .. "\n")
		end
	end
	file:write(string.rep(" ",size-2) .. "}\n")
end

config = {}

function config.load()
	local file, err = io.open(elsa.filesystem.getSaveDirectory() .. "/ocemu.cfg","rb")
	if file == nil then
		print("Problem opening configuration, using default: " .. err)
		_config = {}
		return
	end
	local rawdata = file:read("*a")
	file:close()
	rawdata = rawdata:gsub("\r\n","\n"):gsub("\r","\n")
	rawdata = (rawdata .. "\n"):reverse():match("\n+(.*)"):reverse()
	local data = ""
	for line in (rawdata .. "\n"):gmatch("(.-)\n") do
		if line:match("{%s-$") then
			line = line:gsub("{%s-$","={")
		end
		if line:match("%[%s-$") then
			line = line:gsub("%[%s-$","{")
		end
		if line:match("%]%s-$") then
			line = line:gsub("%]%s-$","}")
		end
		if line:gsub("%s","") ~= "" and not line:match("{%s-$") and not line:match(",%s-$") then
			line = line .. ","
		end
		if line:match("ocemu%s-=%s-{") then
			line = "return {"
		end
		data = data .. line .. "\n"
	end
	data = data:sub(1,-3)
	local fn, err = load(data,"=ocemu.cfg","t",{})
	if not fn then
		error("Problem loading configuration: " .. err,0)
	end
	local ok, cfg = pcall(fn)
	if not ok then
		error("Problem loading configuration: " .. cfg,0)
	end
	_config = cfg
end

function config.save()
	local file, err = io.open(elsa.filesystem.getSaveDirectory() .. "/ocemu.cfg","wb")
	if not file then
		error("Problem opening config for saving: " .. err,0)
	end
	writeComment(comments[1],file,0)
	serialize(_config,"ocemu","",file,2)
	file:close()
end

function config.get(key,default)
	checkArg(1,key,"string")
	if _config == nil then
		error("Configuration not loaded",2)
	end
	local v = _config
	for part in key:gmatch("(.-)%.") do
		if v[part] == nil then
			v[part] = {}
		end
		v = v[part]
	end
	local last = ("." .. key):match(".*%.(.+)")
	if v[last] == nil then
		v[last] = default
	end
	return v[last]
end

function config.set(key,value)
	checkArg(1,key,"string")
	if _config == nil then
		error("Configuration not loaded",2)
	end
	local v = _config
	for part in key:gmatch("(.-)%.") do
		if v[part] == nil then
			v[part] = {}
		end
		v = v[part]
	end
	local last = ("." .. key):match(".*%.(.+)")
	v[last] = value
end
