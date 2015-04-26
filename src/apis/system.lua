local env = ...

env.system = {}

function env.system.allowBytecode()
	cprint("system.allowBytecode")
	return config.get("computer.lua.allowBytecode",false)
end
function env.system.timeout()
	cprint("system.timeout")
	return config.get("computer.timeout",5)
end
