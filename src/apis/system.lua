local env = ...

env.system = {}

function env.system.allowBytecode()
	cprint("system.allowBytecode")
	return settings.allowBytecode
end
function env.system.timeout()
	cprint("system.timeout")
	return settings.timeout
end
