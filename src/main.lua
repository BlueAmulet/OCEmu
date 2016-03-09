if elsa == nil then
	print("Launch boot.lua and not main.lua")
	return
end

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
		error(msg, 4)
	end
end

function tryrequire(...)
	return pcall(require, ...)
end

-- load configuration
elsa.filesystem.load("config.lua")()
config.load()
elsa.filesystem.load("settings.lua")()

elsa.cleanup = {}
function elsa.quit()
	config.save()
	for k,v in pairs(elsa.cleanup) do
		v()
	end
end

if settings.components == nil then
	-- Format: string:type, (string or number or nil):address, (number or nil):slot, component parameters
	-- Read component files for parameter documentation
	settings.components = {
		{"gpu",nil,0,160,50,3},
		{"modem",nil,1,false},
		{"eeprom",nil,9,"lua/bios.lua"},
		{"filesystem",nil,7,"loot/OpenOS",true},
		{"filesystem",nil,nil,"tmpfs",false},
		{"filesystem",nil,5,nil,false},
		{"internet"},
		{"computer"},
		{"ocemu"},
	}
	if elsa.SDL then
		table.insert(settings.components, {"screen_sdl2",nil,nil,80,25,3})
		table.insert(settings.components, {"keyboard_sdl2"})
	else
		-- TODO: Alternatives
	end
	config.set("emulator.components",settings.components)
end

machine = {
	starttime = elsa.timer.getTime(),
	deadline = elsa.timer.getTime(),
	signals = {},
	totalMemory = 2*1024*1024,
}

-- SDL2 causes Segmentation faults when both the Callback and Lua are running.
-- (Removed, code is garbage)

-- Attempt to use SoX's synthesizer, this is safe to use.
--[[
if not machine.beep and os.execute("type sox") then
	function machine.beep(frequency, duration)
		os.execute("play -q -n synth " .. (duration/1000) .. " square " .. frequency .. " vol 0.3 &")
	end
end
--]]
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
		create = coroutine.create,
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
		sethook = debug.sethook,
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
		if type(results[2]) == "function" then
			resume_thread(results[2]())
		elseif type(results[2]) == "number" then
			machine.deadline = elsa.timer.getTime() + results[2]
		elseif type(results[2]) == "boolean" then
			if results[2] then
				modem_host.halt(true)
				boot_machine()
			else
				modem_host.halt(false)
				elsa.quit()
				error("Machine power off",0)
			end
		end
		if coroutine.status(machine.thread) == "dead" and type(results[2]) ~= "function" then
			cprint("machine.lua has died")
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
	if #machine.signals > 0 then
		signal = machine.signals[1]
		table.remove(machine.signals, 1)
		resume_thread(table.unpack(signal, 1, signal.n or #signal))
	elseif elsa.timer.getTime() >= machine.deadline then
		resume_thread()
	end
end
