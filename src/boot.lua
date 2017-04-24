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

local arg_parse = require("support.arg_parse")

local args = arg_parse(...)
local baseDir

local getenv = setmetatable({}, {__index=function(t, k) local v=os.getenv(k) t[k]=v return v end})
local paths = {}

if #args > 0 then
	table.insert(paths, args[1])
elseif ffi.os == 'Windows' then
	if getenv["HOME"] then -- Unlikely but possible thanks to the old code.
		table.insert(paths, getenv["HOME"] .. "\\.ocemu")
	end
	if getenv["APPDATA"] then
		table.insert(paths, getenv["APPDATA"] .. "\\.ocemu")
		table.insert(paths, getenv["APPDATA"] .. "\\OCEmu")
	end
else -- Assume Linux
	if getenv["HOME"] then
		table.insert(paths, getenv["HOME"] .. "/.ocemu")
	end
	if getenv["XDG_CONFIG_HOME"] then
		table.insert(paths, getenv["XDG_CONFIG_HOME"] .. "/ocemu")
	elseif getenv["HOME"] and lfs.attributes(getenv["HOME"] .. "/.config", "mode") == "directory" then
		table.insert(paths, getenv["HOME"] .. "/.config/ocemu")
	end
	if getenv["XDG_DATA_HOME"] then
		table.insert(paths, getenv["XDG_DATA_HOME"] .. "/ocemu")
	elseif getenv["HOME"] and lfs.attributes(getenv["HOME"] .. "/.local/share", "mode") == "directory" then
		table.insert(paths, getenv["HOME"] .. "/.local/share/ocemu")
	end
end
if #paths == 0 then
	table.insert(paths, lfs.currentdir() .. "/data")
end
for i = 1, #paths do
	if lfs.attributes(paths[i], "mode") ~= nil then
		baseDir = paths[i]
		break
	end
end

local preferred = paths[#paths]
if not baseDir then
	baseDir = preferred
end

local baseDirType = lfs.attributes(baseDir, "mode")
if baseDirType ~= nil and baseDirType ~= "directory" then
	error("Emulation storage location '" .. baseDir .. "' is not a directory", 0)
elseif baseDirType == "nil" then
	local ok, err = lfs.mkdir(baseDir)
	if not ok then
		error("Failed to create directory '" .. baseDir .. "':" .. err, 0)
	end
end

if baseDir ~= preferred then
	print("Warning: Using legacy path of '" .. baseDir .. "'")
	print("Please move this to '" .. preferred .. "'")
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
		[SDL.JOYAXISMOTION] = "joyaxismotion",
		[SDL.JOYBALLMOTION] = "joyballmotion",
		[SDL.JOYHATMOTION] = "joyhatmotion",
		[SDL.JOYBUTTONDOWN] = "joybuttondown",
		[SDL.JOYBUTTONUP] = "joybuttonup",
		[SDL.JOYDEVICEADDED] = "joydeviceadded",
		[SDL.JOYDEVICEREMOVED] = "joydeviceremoved",
		[SDL.CONTROLLERAXISMOTION] = "controlleraxismotion",
		[SDL.CONTROLLERBUTTONDOWN] = "controllerbuttondown",
		[SDL.CONTROLLERBUTTONUP] = "controllerbuttonup",
		[SDL.CONTROLLERDEVICEADDED] = "controllerdeviceadded",
		[SDL.CONTROLLERDEVICEREMOVED] = "controllerdeviceremoved",
		[SDL.CONTROLLERDEVICEREMAPPED] = "controllerdeviceremapped",
		[SDL.FINGERDOWN] = "fingerdown",
		[SDL.FINGERUP] = "fingerup",
		[SDL.FINGERMOTION] = "fingermotion",
		[SDL.DOLLARGESTURE] = "dollargesture",
		[SDL.DOLLARRECORD] = "dollarrecord",
		[SDL.MULTIGESTURE] = "multigesture",
		[SDL.CLIPBOARDUPDATE] = "clipboardupdate",
		[SDL.DROPFILE] = "dropfile",
		[SDL.DROPTEXT] = "droptext",
		[SDL.DROPBEGIN] = "dropbegin",
		[SDL.DROPCOMPLETE] = "dropcomplete",
		[SDL.AUDIODEVICEADDED] = "audiodeviceadded",
		[SDL.AUDIODEVICEREMOVED] = "audiodeviceremoved",
		[SDL.RENDER_TARGETS_RESET] = "render_targets_reset",
		[SDL.RENDER_DEVICE_RESET] = "render_device_reset",
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
		args = args,
		getError = function() return ffi.string(SDL.getError()) end,
		filesystem = {
			lines = io.lines,
			load = loadfile,
			read = function(path)
				local file, err = io.open(path, "rb")
				if not file then return nil, err end
				local data = file:read("*a")
				file:close()
				return data, #data
			end,
			write = function(path, data)
				local file, err = io.open(path, "wb")
				if not file then return false, err end
				file:write(data)
				file:close()
				return true
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
				return baseDir
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
		system = {
			getOS = function()
				return ffi.os
			end,
		},
		handlers = {},
		SDL = SDL,
		windowEventID = wen,
	}

	local handlers = elsa.handlers

	setmetatable(elsa, {
		__index=function(t, k)
			return function(...)
				if handlers[k] ~= nil then
					local hndtbl = handlers[k]
					for i=1, #hndtbl do
						hndtbl[i](...)
					end
				end
			end
		end,
		__newindex=function(t, k, v)
			if handlers[k] == nil then
				handlers[k] = {}
			end
			local hndtbl = handlers[k]
			hndtbl[#hndtbl+1]=v
		end
	})

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

	-- seed randomizer
	math.randomseed(os.time())

	require("main")

	local e = ffi.new('SDL_Event')
	while true do
		local start = SDL.getTicks()
		while b(SDL.pollEvent(e)) do
			local event = e
			local etype = eventNames[event.type]
			if etype == nil then
				print("Ignoring event of ID: " .. event.type)
				goto econtinue
			end
			if etype == "windowevent" then
				event = ffi.cast("SDL_WindowEvent*", event)
				if wen[event.event] == nil then
					print("Ignoring window event of kind: " .. event.event)
					goto econtinue
				end
				etype = "window" .. wen[event.event]
			end
			if handlers[etype] ~= nil then
				local hndtbl = handlers[etype]
				for i=1, #hndtbl do
					hndtbl[i](event)
				end
			end
			if etype == "quit" then
				return
			end
			::econtinue::
		end
		local updtbl=handlers.update
		for i=1, #updtbl do
			updtbl[i]()
		end
		if handlers.draw then
			local drawtbl=handlers.draw
			for i=1, #drawtbl do
				drawtbl[i]()
			end
		end

		if settings.fast then
			SDL.delay(16)
		else
			SDL.delay(math.max(start + (1000/20) - SDL.getTicks(), 1))
		end
	end
end

print(xpcall(boot,debug.traceback))
if sdlinit then
	SDL.quit()
end
