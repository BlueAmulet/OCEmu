local env = ...

env.os = setmetatable({},{
	__index = function(_,k)
		cprint("Missing environment access", "env.os." .. k)
	end,
})

env.os.clock = os.clock
env.os.date = os.date
env.os.time = os.time
