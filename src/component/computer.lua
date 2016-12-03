-- computer component
local mai = {}
local obj = {}

mai.isRunning = {direct = true, doc = "function():boolean -- Returns whether the computer is running."}
function obj.isRunning()
	--STUB
	cprint("computer.isRunning")
	return true
end

mai.beep = {doc = "function([frequency:number[, duration:number]]) -- Plays a tone, useful to alert users via audible feedback."}
function obj.beep(frequency, duration)
	--STUB
	cprint("computer.beep", frequency, duration)
	if frequency == nil then frequency = 440 end
	compCheckArg(1,frequency,"number")
	frequency = math.floor(frequency)
	if frequency < 20 or frequency > 2000 then
		error("invalid frequency, must be in [20, 2000]",3)
	end
	if duration == nil then duration = 0.1 end
	compCheckArg(2,duration,"number")
	local durationMS = math.max(50, math.min(5000, math.floor(duration * 1000)))
	machine.beep(frequency, durationMS)
	machine.sleep(durationMS/1000)
end

mai.stop = {doc = "function():boolean -- Stops the computer. Returns true if the state changed."}
function obj.stop()
	--STUB
	cprint("computer.stop")
end

mai.start = {doc = "function():boolean -- Starts the computer. Returns true if the state changed."}
function obj.start()
	--STUB
	cprint("computer.start")
end

mai.getDeviceInfo = {direct = true, doc = "function():table -- Collect information on all connected devices."}
function obj.getDeviceInfo()
	--STUB
	cprint("computer.getDeviceInfo")
end

mai.getProgramLocations = {doc = "function():table -- Returns a list of available programs and their install disks."}
function obj.getProgramLocations()
	cprint("computer.getProgramLocations")
	return table.pack(
		table.pack("build", "builder"),
		table.pack("dig", "dig"),
		table.pack("base64", "data"),
		table.pack("deflate", "data"),
		table.pack("gpg", "data"),
		table.pack("inflate", "data"),
		table.pack("md5sum", "data"),
		table.pack("sha256sum", "data"),
		table.pack("refuel", "generator"),
		table.pack("irc", "irc"),
		table.pack("maze", "maze"),
		table.pack("arp", "network"),
		table.pack("ifconfig", "network"),
		table.pack("ping", "network"),
		table.pack("route", "network"),
		table.pack("opl-flash", "openloader"),
		table.pack("oppm", "oppm")
	)
end

return obj,nil,mai
