if love ~= nil then
	print("OCEmu is not a Love2D application")
	os.exit()
elseif elsa == nil then
	print("Launch boot.lua and not main.lua")
	return
end

local requirements = true
if not elsa.filesystem.exists("lua") then
	requirements = false
	print("Missing lua/ folder, please use Makefile or download from OpenComputers's repo")
end
if not elsa.filesystem.exists("loot") then
	requirements = false
	print("Missing loot/ folder, please use Makefile or download from OpenComputers's repo")
end
if not elsa.filesystem.exists("font.hex") then
	requirements = false
	print("Missing font.hex file, please use Makefile or download from OpenComputers's repo")
end
if not requirements then
	error("Missing required resources", 0)
end

local ffi = require("ffi")

local windows = (elsa.system.getOS() == "Windows")

function math.trunc(n)
	return n < 0 and math.ceil(n) or math.floor(n)
end

local function check(have, want, ...)
	if not want then
		return false
	else
		return have == want or check(have, ...)
	end
end

function checkArg(n, have, ...)
	have = type(have)
	if not check(have, ...) then
		local msg = string.format("bad argument #%d (%s expected, got %s)", n, table.concat({...}, " or "), have)
		error(msg, 3)
	end
end

function compCheckArg(n, have, ...)
	have = type(have)
	if not check(have, ...) then
		local msg = string.format("bad arguments #%d (%s expected, got %s)", n, table.concat({...}, " or "), have)
		error(msg, 0)
	end
end

function tryrequire(...)
	return pcall(require, ...)
end

function string_trim(s)
	local from = s:match"^%s*()"
	return from > #s and "" or s:match(".*%S", from)
end

-- load configuration
elsa.filesystem.load("config.lua")()
config.load()
elsa.filesystem.load("settings.lua")()

function elsa.quit()
	config.save()
end

if settings.components == nil then
	-- Format: string:type, (string or number or nil):address, (number or nil):slot, component parameters
	-- Read component files for parameter documentation
	settings.components = {
		{"gpu",nil,0,160,50,3},
		{"modem",nil,1,false},
		{"eeprom",nil,9,"lua/bios.lua"},
		{"filesystem",nil,7,"loot/openos","openos",true,1},
		{"filesystem",nil,-1,"tmpfs","tmpfs",false,5},
		{"filesystem",nil,5,nil,nil,false,4},
		{"internet",nil,2},
		{"computer",nil,-1},
		{"ocemu",nil,-1},
	}
	if elsa.SDL then
		table.insert(settings.components, {"screen_sdl2",nil,-1,80,25,3})
		table.insert(settings.components, {"keyboard_sdl2",nil,-1})
	else
		-- TODO: Alternatives
	end
	config.set("emulator.components",settings.components)
end

--[[local memoryUsages = {}

local profilerHook = function(event)
	local func = debug.getinfo(2)
	if func == nil then return end
	local name = func.name
	if name ~= nil then
		if event == "call" or event == "tail call" then
			memoryUsages[name] = collectgarbage("count")
		elseif event == "return" then
			memoryUsages[name] = collectgarbage("count") - memoryUsages[name]
		end
	end
end]]

local maxCallBudget = (1.5 + 1.5 + 1.5) / 3 -- T3 CPU and 2 T3+ memory

machine = {
	starttime = elsa.timer.getTime(),
	deadline = elsa.timer.getTime(),
	signals = {},
	totalMemory = 2*1024*1024,
	insynccall = false,
}

function machine.consumeCallBudget(callCost)
	if not settings.fast and not machine.insynccall then
		machine.callBudget = machine.callBudget - math.max(0.001, callCost)
		if machine.callBudget < 0 then
			cprint("Ran out of budget", callCost, 1/callCost)
			return false
		end
	end
	return true
end

if not machine.beep and settings.beepVolume <= 0 then
	function machine.beep(frequency, duration)
		cprint("BEEP (Silent)", frequency, duration)
	end
end
if not machine.beep and elsa.SDL then
	local desired = ffi.new("SDL_AudioSpec",{freq=settings.beepSampleRate, format=elsa.SDL.AUDIO_U8, channels=1, samples=4096, callback=ffi.NULL})
	local obtained = ffi.new("SDL_AudioSpec",{})
	local dev = elsa.SDL.openAudioDevice(ffi.NULL, 0, desired, obtained, 0)
	if dev == 0 then
		print(elsa.getError())
	else
		local same=true
		for k,v in pairs({"freq", "format", "channels"}) do
			if desired[v] ~= obtained[v] then
				same = false
				print(v .. ") " .. desired[v] .. " -> " .. obtained[v])
			end
		end
		if same then
			elsa.SDL.pauseAudioDevice(dev, 0)
			local datatype = ffi.typeof("int8_t[?]")
			local rate = tonumber(obtained.freq)
			local vol = settings.beepVolume
			local offset = 0
			function machine.beep(frequency, duration)
				local step = frequency/rate
				local sampleCount = math.floor(duration*rate/1000)
				local data = datatype(sampleCount)
				for i=1, sampleCount do
					data[i-1] = bit32.bxor(offset < 0.5 and vol or -vol, 0x80)
					offset = (offset + step) % 1
				end
				if elsa.SDL.queueAudio(dev, data, sampleCount) ~= 0 then
					error(elsa.getError())
				end
			end
		else
			print("Could not obtain requested audio format.")
		end
	end
end
-- Attempt to use SoX's synthesizer, this is safe to use.
if not machine.beep and (not windows and os.execute("type sox")) then
	function machine.beep(frequency, duration)
		os.execute("play -q -n synth " .. (duration/1000) .. " square " .. frequency .. " vol 0.3 &")
	end
end
if not machine.beep then
	function machine.beep(frequency, duration)
		cprint("BEEP", frequency, duration)
	end
end

if not machine.sleep and elsa.SDL then
	function machine.sleep(s)
		elsa.SDL.delay(s*1000)
	end
end if not machine.sleep then
	local sok, socket = tryrequire("socket")
	if sok then
		function machine.sleep(s)
			socket.sleep(s)
		end
	end
end if not machine.sleep then
	function machine.sleep() end
end

if settings.emulatorDebug then
	cprint = print
else
	cprint = function() end
end

local env = {
	_VERSION = "Lua 5.2",
	assert = assert,
	bit32 = {
		arshift = bit32.arshift,
		band = bit32.band,
		bnot = bit32.bnot,
		bor = bit32.bor,
		btest = bit32.btest,
		bxor = bit32.bxor,
		extract = bit32.extract,
		lrotate = bit32.lrotate,
		lshift = bit32.lshift,
		replace = bit32.replace,
		rrotate = bit32.rrotate,
		rshift = bit32.rshift,
	},
	collectgarbage = collectgarbage,
	coroutine = {
		create = function(...)
			local c = coroutine.create(...)
			if settings.profiler then
				debug.sethook(c, profilerHook, "cr")
			end
			return c
		end,
		resume = coroutine.resume,
		running = coroutine.running,
		status = coroutine.status,
		wrap = coroutine.wrap,
		yield = coroutine.yield,
	},
	debug = {
		debug = debug.debug,
		gethook = debug.gethook,
		getinfo = debug.getinfo,
		getlocal = debug.getlocal,
		getmetatable = debug.getmetatable,
		getregistry = debug.getregistry,
		getupvalue = debug.getupvalue,
		getuservalue = debug.getuservalue,
		sethook = function(...)
			if not select(1, ...) then
				if settings.profiler then
					cprint("attempt to clear hooks")
					debug.sethook()
					cprint("adding profiler hook")
					debug.sethook(profilerHook, "cr")
				end
			else
				debug.sethook(...)
			end
		end,
		setlocal = debug.setlocal,
		setmetatable = debug.setmetatable,
		setupvalue = debug.setupvalue,
		setuservalue = debug.setuservalue,
		traceback = debug.traceback,
		upvalueid = debug.upvalueid,
		upvaluejoin = debug.upvaluejoin,
	},
	error = error,
	getmetatable = getmetatable,
	io = {
		close = io.close,
		flush = io.flush,
		input = io.input,
		lines = io.lines,
		open = io.open,
		output = io.output,
		popen = io.popen,
		read = io.read,
		stderr = io.stderr,
		stdin = io.stdin,
		stdout = io.stdout,
		tmpfile = io.tmpfile,
		type = io.type,
		write = io.write,
	},
	ipairs = ipairs,
	load = load,
	math = {
		abs = math.abs,
		acos = math.acos,
		asin = math.asin,
		atan = math.atan,
		atan2 = math.atan2,
		ceil = math.ceil,
		cos = math.cos,
		cosh = math.cosh,
		deg = math.deg,
		exp = math.exp,
		floor = math.floor,
		fmod = math.fmod,
		frexp = math.frexp,
		huge = math.huge,
		ldexp = math.ldexp,
		log = math.log,
		max = math.max,
		min = math.min,
		modf = math.modf,
		pi = math.pi,
		pow = math.pow,
		rad = math.rad,
		random = math.random,
		randomseed = math.randomseed,
		sin = math.sin,
		sinh = math.sinh,
		sqrt = math.sqrt,
		tan = math.tan,
		tanh = math.tanh,
	},
	next = next,
	pairs = pairs,
	pcall = pcall,
	print = print,
	rawequal = rawequal,
	rawget = rawget,
	rawlen = rawlen,
	rawset = rawset,
	require = require,
	select = select,
	setmetatable = setmetatable,
	string = {
		byte = string.byte,
		char = string.char,
		dump = string.dump,
		find = string.find,
		format = string.format,
		gmatch = string.gmatch,
		gsub = string.gsub,
		len = string.len,
		lower = string.lower,
		match = string.match,
		rep = string.rep,
		reverse = string.reverse,
		sub = string.sub,
		upper = string.upper,
	},
	table = {
		concat = table.concat,
		insert = table.insert,
		pack = table.pack,
		remove = table.remove,
		sort = table.sort,
		unpack = table.unpack,
	},
	tonumber = tonumber,
	tostring = tostring,
	type = type,
	xpcall = xpcall,
}
if _VERSION == "Lua 5.3" then
	env._VERSION = "Lua 5.3"
	env.coroutine.isyieldable = coroutine.isyieldable
	env.math.maxinteger = math.maxinteger
	env.math.mininteger = math.mininteger
	env.math.tointeger = math.tointeger
	env.math.type = math.type
	env.math.ult = math.ult
	env.string.pack = string.pack
	env.string.packsize = string.packsize
	env.string.unpack = string.unpack
	env.table.move = table.move
	env.utf8 = {}
	for k,v in pairs(utf8) do
		env.utf8[k] = v
	end
end
setmetatable(env,{
	__index = function(_,k)
		cprint("Missing environment access", "env." .. k)
	end,
})

-- load font
font = {}
for line in elsa.filesystem.lines("font.hex") do
	local a,b = line:match("(.+):(.*)")
	font[tonumber(a,16)] = b
end
function getCharWidth(char)
	if font[char] ~= nil then
		return #font[char] / 32
	end
	return 1
end

-- load api's into environment
elsa.filesystem.load("apis/computer.lua")(env)
elsa.filesystem.load("apis/os.lua")(env)
elsa.filesystem.load("apis/system.lua")(env)
elsa.filesystem.load("apis/unicode.lua")(env)
elsa.filesystem.load("apis/userdata.lua")(env)
elsa.filesystem.load("apis/component.lua")(env)

config.save()

function boot_machine()
	-- load machine.lua
	local machine_data, err = elsa.filesystem.read("lua/machine.lua")
	if machine_data == nil then
		error("Failed to load machine.lua:\n\t" .. tostring(err))
	end
	local machine_fn, err = load(machine_data,"=machine","t",env)
	if machine_fn == nil then
		error("Failed to parse machine.lua\n\t" .. tostring(err))
	end
	machine.thread = coroutine.create(machine_fn)
	if settings.profiler then
		print("hook profiler to machine thread")
		debug.sethook(machine.thread, profilerHook, "cr")
	end
	local results = { coroutine.resume(machine.thread) }
	if results[1] then
		if #results ~= 1 then
			error("Unexpected result during initialization:\n\t",table.concat(results,", ",2))
		end
	else
		error("Failed to initialize machine.lua\n\t" .. tostring(results[2]))
	end
	cprint("Machine.lua booted ...")
end

local biglist, err = loadfile("biglist.lua")
if not biglist then
	error(err)
end
biglist=biglist()

boot_machine()

local resume_thread
function resume_thread(...)
	timeoffset = 0
	if coroutine.status(machine.thread) ~= "dead" then
		cprint("resume",...)
		local results = table.pack(coroutine.resume(machine.thread, ...))
		cprint("yield",table.unpack(results))
		if coroutine.status(machine.thread) ~= "dead" then
			if type(results[2]) == "function" then
				if settings.fast then
					elsa.draw()
					resume_thread(results[2]())
				else
					machine.syncfunc = results[2]
				end
			elseif type(results[2]) == "boolean" then
				if results[2] then
					modem_host.halt(true)
					boot_machine()
				else
					modem_host.halt(false)
					elsa.quit()
					error("Machine power off",0)
				end
			elseif type(results[2]) == "number" then
				machine.deadline = elsa.timer.getTime() + results[2]
			end
		else
			modem_host.halt(false)
			elsa.quit()
			if type(results[2]) ~= "boolean" or (type(results[3]) ~= "string" and results[3] ~= nil) then
				error("Kernel returned unexpected results.", 0)
			elseif results[2] then
				error("Kernel stopped unexpectedly", 0)
			else
				error(results[3], 0)
			end
		end
		if machine.biglistgen then
			print("BigList")
			machine.biglistgen = false
			collectgarbage("collect")
			biglist.dump(machine.thread,"(main)")
		end
	end
end

kbdcodes = {}

function elsa.update(dt)
	if #kbdcodes > 0 then
		local kbdcode = kbdcodes[1]
		table.remove(kbdcodes,1)
		table.insert(machine.signals,{kbdcode.type,kbdcode.addr,kbdcode.char or 0,kbdcode.code})
	end
	if modem_host then
		modem_host.processPendingMessages()
	end
	machine.callBudget = maxCallBudget
	if machine.syncfunc then
		local func = machine.syncfunc
		machine.syncfunc = nil
		machine.insynccall = true
		local result = func() -- should be a table
		machine.insynccall = false
		resume_thread(result)
	elseif #machine.signals > 0 then
		signal = machine.signals[1]
		table.remove(machine.signals, 1)
		resume_thread(table.unpack(signal, 1, signal.n or #signal))
	elseif elsa.timer.getTime() >= machine.deadline then
		resume_thread()
	end
end
