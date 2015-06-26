local address, _, wireless = ...
compCheckArg(1,wireless,"boolean")

local wakeMessage
local strength
if wireless then
	strength = settings.maxWirelessRange
end

local function checkPort(port)
	if port < 1 and port >= 65536 then
		error("invalid port number",4)
	end
	return math.floor(port)
end

-- modem component
local obj = {}

function obj.send(address, port, ...) -- Sends the specified data to the specified target.
	--STUB
	cprint("modem.send",address, port, ...)
	compCheckArg(1,address,"string")
	compCheckArg(2,port,"number")
	port=checkPort(port)
	return true
end
function obj.getWakeMessage() -- Get the current wake-up message.
	--STUB
	cprint("modem.getWakeMessage")
	return wakeMessage
end
function obj.setWakeMessage(message) -- Set the wake-up message.
	--STUB
	cprint("modem.setWakeMessage",message)
	compCheckArg(1,message,"string","nil")
	wakeMessage = message
end
function obj.close(port) -- Closes the specified port (default: all ports). Returns true if ports were closed.
	--STUB
	cprint("modem.close",port)
	compCheckArg(1,port,"number","nil")
	if port ~= nil then
		port=checkPort(port)
	end
	return false
end
function obj.maxPacketSize() -- Gets the maximum packet size (config setting).
	cprint("modem.maxPacketSize")
	return settings.maxNetworkPacketSize
end
if wireless then
	function obj.getStrength() -- Get the signal strength (range) used when sending messages.
		--STUB
		cprint("modem.getStrength")
		return strength
	end
	function obj.setStrength(newstrength) -- Set the signal strength (range) used when sending messages.
		--STUB
		cprint("modem.setStrength",newstrength)
		compCheckArg(1,newstrength,"number")
		strength = newstrength
	end
end
function obj.isOpen(port) -- Whether the specified port is open.
	--STUB
	cprint("modem.isOpen",port)
	compCheckArg(1,port,"number")
	return false
end
function obj.open(port) -- Opens the specified port. Returns true if the port was opened.
	--STUB
	cprint("modem.open",port)
	compCheckArg(1,port,"number")
	port=checkPort(port)
	return false
end
function obj.isWireless() -- Whether this is a wireless network card.
	--STUB
	cprint("modem.isWireless")
	return wireless
end
function obj.broadcast(port, ...) -- Broadcasts the specified data on the specified port.
	--STUB
	cprint("modem.broadcast",port, ...)
	compCheckArg(1,port,"number")
	port=checkPort(port)
	return true
end

local cec = {}

local doc = {
	["send"]="function(address:string, port:number, data...) -- Sends the specified data to the specified target.",
	["getWakeMessage"]="function():string -- Get the current wake-up message.",
	["setWakeMessage"]="function(message:string):string -- Set the wake-up message.",
	["close"]="function([port:number]):boolean -- Closes the specified port (default: all ports). Returns true if ports were closed.",
	["maxPacketSize"]="function():number -- Gets the maximum packet size (config setting).",
	["getStrength"]="function():number -- Get the signal strength (range) used when sending messages.",
	["setStrength"]="function(strength:number):number -- Set the signal strength (range) used when sending messages.",
	["isOpen"]="function(port:number):boolean -- Whether the specified port is open.",
	["open"]="function(port:number):boolean -- Opens the specified port. Returns true if the port was opened.",
	["isWireless"]="function():boolean -- Whether this is a wireless network card.",
	["broadcast"]="function(port:number, data...) -- Broadcasts the specified data on the specified port.",
}

return obj,cec,doc
