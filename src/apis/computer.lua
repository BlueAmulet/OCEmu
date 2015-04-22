local env = ...

local tmpaddr = "tmp-address"

computer = {}

function computer.setTempAddress(str)
	tmpaddr = str
end

env.computer = {}

function env.computer.realTime()
	--STUB
	--cprint("computer.realTime") -- Spammy
	return 0
end
function env.computer.uptime()
	--STUB
	cprint("computer.uptime")
	return love.timer.getTime() - machine.starttime
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
	--TODO
	cprint("computer.pushSignal", name, ...)
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
	return nil, "player must be online"
end
function env.computer.removeUser(username)
	--STUB
	cprint("computer.removeUser", username)
	return false
end
function env.computer.energy()
	--STUB
	cprint("computer.energy")
	return math.huge
end
function env.computer.maxEnergy()
	--STUB
	cprint("computer.maxEnergy")
	return math.huge
end
