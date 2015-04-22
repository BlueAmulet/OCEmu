local env = ...

env.system = {}

function env.system.allowBytecode()
	--STUB, move to a config
	cprint("system.allowBytecode")
	return false
end
function env.system.timeout()
	--STUB, move to a config
	cprint("system.timeout")
	return math.huge
end
