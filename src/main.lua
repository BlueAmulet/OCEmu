if elsa == nil then
	print("Launch boot.lua and not main.lua")
	return
end

function math.trunc(n)
	return n < 0 and math.ceil(n) or math.floor(n)
end

-- load configuration
elsa.filesystem.load("config.lua")()
config.load()

elsa.cleanup = {}
function elsa.quit()
	config.save()
	for k,v in pairs(elsa.cleanup) do
		v()
	end
end

conf = {
	-- Format: string:type, (string or number or nil):address, (number or nil):slot, component parameters
	-- Read component files for parameter documentation
	components = {
		{"gpu",nil,0,160,50,3},
		{"eeprom",nil,9,"lua/bios.lua"},
		{"filesystem",nil,7,"loot/OpenOS",true},
		{"filesystem",nil,nil,"tmpfs",false},
		{"filesystem",nil,5,nil,false},
		{"internet"},
		{"computer"},
		{"ocemu"},
	}
}
if elsa.SDL then
	table.insert(conf.components, {"screen_sdl2",nil,nil,80,25,3})
	table.insert(conf.components, {"keyboard_sdl2"})
else
	-- TODO: Alternatives
end

machine = {
	starttime = elsa.timer.getTime(),
	deadline = elsa.timer.getTime(),
	signals = {},
}

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

if true then
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
	dofile = dofile,
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
	loadfile = loadfile,
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
		pi = 3.1415926535898,
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
	os = {
		clock = os.clock,
		date = os.date,
		difftime = os.difftime,
		execute = os.execute,
		exit = os.exit,
		getenv = os.getenv,
		remove = os.remove,
		rename = os.rename,
		setlocale = os.setlocale,
		time = os.time,
		tmpname = os.tmpname,
	},
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
setmetatable(env,{
	__index = function(_,k)
		cprint("Missing environment access", "env." .. k)
	end,
})

-- load unifont
unifont = {}
for line in elsa.filesystem.lines("unifont.hex") do
	local a,b = line:match("(.+):(.*)")
	unifont[tonumber(a,16)] = b
end
function getCharWidth(char)
	if unifont[char] ~= nil then
		return #unifont[char] / 32
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

boot_machine()

local resume_thread
function resume_thread(...)
	timeoffset = 0
	if coroutine.status(machine.thread) ~= "dead" then
		cprint("resume",...)
		local results = { coroutine.resume(machine.thread, ...) }
		cprint("yield",table.unpack(results))
		if type(results[2]) == "function" then
			resume_thread(results[2]())
		elseif type(results[2]) == "number" then
			machine.deadline = elsa.timer.getTime() + results[2]
		elseif type(results[2]) == "boolean" then
			if results[2] then
				boot_machine()
			else
				error("Machine power off",0)
			end
		end
		if coroutine.status(machine.thread) == "dead" and type(results[2]) ~= "function" then
			cprint("machine.lua has died")
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
	if #machine.signals > 0 then
		signal = machine.signals[1]
		table.remove(machine.signals, 1)
		resume_thread(table.unpack(signal))
	elseif elsa.timer.getTime() >= machine.deadline then
		resume_thread()
	end
end
