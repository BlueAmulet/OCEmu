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
			read = function(filename)
				local file, err = io.open(filename,"rb")
				if not file then return nil, err end
				local data = file:read("*a")
				file:close()
				return data, #data
			end,
			exists = function(filename)
				return lfs.attributes(filename,"mode") ~= nil
			end,
			isDirectory = function(filename)
				return lfs.attributes(filename,"mode") == "directory"
			end,
			createDirectory = lfs.mkdir,
			newFile = function(filename, mode)
				return io.open(filename, mode .. "b")
			end,
			getDirectoryItems = function(path)
				local list = {}
				for entry in lfs.dir(path) do
					list[#list+1] = entry
				end
				return list
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
