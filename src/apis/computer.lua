local env = ...

local sok,socket = pcall(require,"socket")
local gettime
if sok then
	gettime = socket.gettime
else
	gettime = os.time
end

local tmpaddr = "tmp-address"

computer = {}

function computer.setTempAddress(str)
	tmpaddr = str
end

env.computer = {}

function env.computer.realTime()
	--TODO
	--cprint("computer.realTime") -- Spammy
	return gettime()
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
	return 10000
end
function env.computer.totalMemory()
	--STUB
	cprint("computer.totalMemory")
	return 10000
end
function env.computer.pushSignal(name, ...)
	cprint("computer.pushSignal", name, ...)
	compCheckArg(1,name,"string")
	table.insert(machine.signals, {name, ... })
end
function env.computer.tmpAddress()
	--STUB
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
	--STUB, move to a config
	cprint("computer.maxEnergy")
	return 500
end
