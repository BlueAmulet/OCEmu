#!/usr/bin/lua5.2
local SDL = require("SDL")
local lfs = require("lfs")

local sdlinit = false

local function boot()
	local ret, err = SDL.init {
		SDL.flags.Audio,
		SDL.flags.Events,
    	SDL.flags.Video,
		SDL.flags.NoParachute,
	}

	if not ret then
		error(err)
	end
	sdlinit = true

	local eventNames = {}
	for k,v in pairs(SDL.event) do
		eventNames[v] = k:lower()
	end

	local wen = {}
	for k,v in pairs(SDL.eventWindow) do
		wen[v] = k:lower()
	end

	elsa = {
		getError = SDL.getError,
		filesystem = {
			lines = io.lines,
			load = loadfile,
			read = function(path)
				local file, err = io.open(path,"rb")
				if not file then return nil, err end
				local data = file:read("*a")
				file:close()
				return data, #data
			end,
			exists = function(path)
				return lfs.attributes(path,"mode") ~= nil
			end,
			isDirectory = function(path)
				return lfs.attributes(path,"mode") == "directory"
			end,
			createDirectory = function(path)
				local pstr = ""
				for part in (path .. "/"):gmatch("(.-)[\\/]") do
					pstr = pstr .. part
					lfs.mkdir(pstr)
					pstr = pstr .. "/"
				end
				return lfs.attributes(path,"mode") ~= nil
			end,
			newFile = function(path, mode)
				return io.open(path, mode .. "b")
			end,
			getDirectoryItems = function(path)
				local list = {}
				for entry in lfs.dir(path) do
					if entry ~= "." and entry ~= ".." then
						list[#list+1] = entry
					end
				end
				return list
			end,
			getLastModified = function(path)
				return lfs.attributes(path,"modification")
			end,
			getSize = function(path)
				return lfs.attributes(path,"size")
			end,
			getSaveDirectory = function()
				return (os.getenv("HOME") or os.getenv("APPDATA")) .. "/.ocemu"
			end
		},
		timer = {
			getTime = function()
				return SDL.getTicks()/1000
			end,
			sleep = function(s)
				SDL.delay(s*1000)
			end,
		},
		window = {
			createWindow = SDL.createWindow,
		},
		graphics = {	
			createRenderer = SDL.createRenderer,
		}
	}
	
	require("main")
	
	while true do
		for e in SDL.pollEvent() do
			e.type = eventNames[e.type]
			if e.type == "windowevent" then
				e.event = wen[e.event]
			end
			if e.type == "quit" then
				return
			end
			if elsa[e.type] ~= nil then
				elsa[e.type](e)
			end
		end
		elsa.update()
		if elsa.draw then
			elsa.draw()
		end
		
		SDL.delay(1)
	end
end
print(xpcall(boot,debug.traceback))
if sdlinit then 
	SDL.quit()
end
