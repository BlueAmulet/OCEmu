local env = ...

local sok, socket = tryrequire("socket")
if sok then
	gettime = socket.gettime
else
	gettime = os.time
end
timeoffset = 0

local tmpaddr = "tmp-address"

computer = {}

function computer.setTempAddress(str)
	tmpaddr = str
end

env.computer = setmetatable({},{
	__index = function(_,k)
		cprint("Missing environment access", "env.computer." .. k)
	end,
})

function env.computer.realTime()
	--TODO
	--cprint("computer.realTime") -- Spammy
	return gettime()-timeoffset
end
function env.computer.uptime()
	--TODO
	cprint("computer.uptime")
	return elsa.timer.getTime() - machine.starttime
end
function env.computer.address()
	cprint("computer.address")
	return component.list("computer",true)()
end
function env.computer.freeMemory()
	--STUB
	cprint("computer.freeMemory")
	return machine.totalMemory
end
function env.computer.totalMemory()
	--STUB
	cprint("computer.totalMemory")
	return machine.totalMemory
end
local signalWhitelist={["nil"]=true,boolean=true,string=true,number=true}
function env.computer.pushSignal(name, ...)
	cprint("computer.pushSignal", name, ...)
	compCheckArg(1,name,"string")
	local signal = {n = select("#", ...) + 1, name, ... }
	for i = 2, signal.n do
		if not signalWhitelist[type(signal[i])] then
			signal[i] = nil
		end
	end
	table.insert(machine.signals, signal)
end
function env.computer.tmpAddress()
	cprint("computer.tmpAddress")
	return tmpaddr
end
function env.computer.users()
	--STUB
	cprint("computer.users")
end
function env.computer.addUser(username)
	--STUB
	cprint("computer.addUser", username)
	compCheckArg(1,username,"string")
	return nil, "player must be online"
end
function env.computer.removeUser(username)
	--STUB
	cprint("computer.removeUser", username)
	compCheckArg(1,username,"string")
	return false
end
function env.computer.energy()
	--STUB
	cprint("computer.energy")
	return math.huge
end
function env.computer.maxEnergy()
	-- TODO: What is this ...
	cprint("computer.maxEnergy")
	return 1500
end
function env.computer.getArchitectures()
	--STUB
	cprint("computer.getArchitectures")
	return {_VERSION,n=1}
end
function env.computer.getArchitecture()
	--STUB
	cprint("computer.getArchitecure")
	return _VERSION
end
function env.computer.setArchitecture(archName)
	--STUB
	cprint("computer.setArchitecture")
	compCheckArg(1,archName,"string")
	if archName ~= _VERSION then
		return nil, "unknown architecture"
	end
	return false
end
