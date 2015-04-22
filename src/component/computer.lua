-- computer component
local obj = {}

function obj.isRunning() -- Returns whether the computer is running.
	--STUB
	cprint("computer.isRunning")
end
function obj.beep(frequency, duration) -- Plays a tone, useful to alert users via audible feedback.
	--STUB
	cprint("computer.beep", frequency, duration)
end
function obj.stop() -- Stops the computer. Returns true if the state changed.
	--STUB
	cprint("computer.stop")
end
function obj.start() -- Starts the computer. Returns true if the state changed.
	--STUB
	cprint("computer.start")
end

local cec = {}

return obj,cec
