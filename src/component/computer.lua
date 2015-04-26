-- computer component
local obj = {}

function obj.isRunning() -- Returns whether the computer is running.
	--STUB
	cprint("computer.isRunning")
	return true
end
function obj.beep(frequency, duration) -- Plays a tone, useful to alert users via audible feedback.
	--STUB
	cprint("computer.beep", frequency, duration)
	compCheckArg(1,frequency,"number","nil")
	compCheckArg(2,duration,"number","nil")
	frequency = frequency or 440
	duration = duration or 0.1
	if frequency < 20 or frequency > 2000 then
		error("invalid frequency, must be in [20, 2000]",3)
	end
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

local doc = {
	["isRunning"]="function():boolean -- Returns whether the computer is running.",
	["beep"]="function([frequency:number[, duration:number]]) -- Plays a tone, useful to alert users via audible feedback.",
	["stop"]="function():boolean -- Stops the computer. Returns true if the state changed.",
	["start"]="function():boolean -- Starts the computer. Returns true if the state changed.",
}

return obj,cec,doc
