#!/usr/bin/lua5.2
if package.cpath:find(".dll",nil,true) then
	package.cpath=".\\extras\\?.dll;" .. package.cpath
	package.path=".\\extras\\?\\init.lua;.\\extras\\?.lua;" .. package.path
end

local function b(a) return a ~= 0 end
local ffi = require("ffi")
local SDL = require("sdl2.init")
local lfs = require("lfs")

local sdlinit = false

local args = table.pack(...)
local emulationInstancePath = (os.getenv("HOME") or os.getenv("APPDATA")) .. "/.ocemu"

if #args > 0 then
	emulationInstancePath = args[1]
end

local function boot()
	local ret, err = not b(SDL.init(SDL.INIT_AUDIO + SDL.INIT_EVENTS + SDL.INIT_VIDEO))

	if not ret then
		error(ffi.string(SDL.getError))
	end
	sdlinit = true

	local eventNames = {
		[SDL.FIRSTEVENT] = "firstevent",
		[SDL.QUIT] = "quit",
		[SDL.APP_TERMINATING] = "app_terminating",
		[SDL.APP_LOWMEMORY] = "app_lowmemory",
		[SDL.APP_WILLENTERBACKGROUND] = "app_willenterbackground",
		[SDL.APP_DIDENTERBACKGROUND] = "app_didenterbackground",
		[SDL.APP_WILLENTERFOREGROUND] = "app_willenterforeground",
		[SDL.APP_DIDENTERFOREGROUND] = "app_didenterforeground",
		[SDL.WINDOWEVENT] = "windowevent",
		[SDL.SYSWMEVENT] = "syswmevent",
		[SDL.KEYDOWN] = "keydown",
		[SDL.KEYUP] = "keyup",
		[SDL.TEXTEDITING] = "textediting",
		[SDL.TEXTINPUT] = "textinput",
		[SDL.MOUSEMOTION] = "mousemotion",
		[SDL.MOUSEBUTTONDOWN] = "mousebuttondown",
		[SDL.MOUSEBUTTONUP] = "mousebuttonup",
		[SDL.MOUSEWHEEL] = "mousewheel",
	}

	local wen = {}
	for k,v in pairs(SDL) do
		if k:sub(1,12) == "WINDOWEVENT_" then
			wen[v] = k:sub(13):lower()
		end
	end

	local recursiveDelete
	function recursiveDelete(path)
		local mode = lfs.attributes(path,"mode")
		if mode == nil then
			return false
		elseif mode == "directory" then
			local stat = true
			for entry in lfs.dir(path) do
				if entry ~= "." and entry ~= ".." then
					local mode = lfs.attributes(path .. "/" .. entry,"mode")
					if mode == "directory" then
						recursiveDelete(path .. "/" .. entry)
					end
					os.remove(path .. "/" .. entry)
				end
			end
		end
		return os.remove(path)
	end

	elsa = {
		getError = function() return ffi.string(SDL.getError()) end,
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
				return emulationInstancePath
			end,
			remove = function(path)
				return recursiveDelete(path)
			end,
		},
		timer = {
			getTime = function()
				return SDL.getTicks()/1000
			end,
		},
		SDL = SDL,
		windowEventID = wen,
	}

	-- redirect os.remove is non posix
	if ffi.os == 'Windows' then
		local os_remove = os.remove
		os.remove = function(path)
			local mode = lfs.attributes(path,"mode")
			if mode == nil then
				return false
			elseif mode == "directory" then
				return lfs.rmdir(path)
			else -- remove file
				return os_remove(path)
			end
		end
	end

	require("main")

	local e = ffi.new('SDL_Event')
	while true do
		while b(SDL.pollEvent(e)) do
			local etype = eventNames[e.type]
			if etype == nil then
				print("Ignoring event of ID: " .. e.type)
				goto econtinue
			end
			if elsa[etype] ~= nil then
				elsa[etype](e)
			end
			if etype == "quit" then
				return
			end
			::econtinue::
		end
		elsa.update()
		if elsa.draw then
			elsa.draw()
		end

		SDL.delay(16)
	end
end

print(xpcall(boot,debug.traceback))
if sdlinit then
	SDL.quit()
end
