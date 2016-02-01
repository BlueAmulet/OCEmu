local env = ...

env.system = setmetatable({},{
	__index = function(_,k)
		cprint("Missing environment access", "env.system." .. k)
	end,
})

function env.system.allowBytecode()
	cprint("system.allowBytecode")
	return settings.allowBytecode
end
function env.system.allowGC()
	cprint("system.allowGC")
	return settings.allowGC
end
function env.system.timeout()
	cprint("system.timeout")
	return settings.timeout
end
