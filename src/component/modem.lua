local address, _, wireless = ...
print(address, _, wireless);
compCheckArg(1,wireless,"boolean")

local socket = require("socket")
local ser = require("loot.OpenOS.lib.serialization")

-- yes, global
modem_host = {}

-- modem component
local obj = {}

-- Modem cards communicate on a real backend port
modem_host.comms_port = 61234
modem_host.comms_ip = "127.0.0.10"
modem_host.connected = false
modem_host.messages = {}
modem_host.socket = nil

modem_host.hosting = false
modem_host.clients = {}

-- [port_number] = true when open
modem_host.open_ports = {}

local function createPacket(type, address, port, ...)
	-- args are not checked here (unlike the modem api methods)
	-- address can be nil, which means broadcast
	local packed =
	{
		type or "unknown_type",
		address or "no address",
		modem_host.id or "no sender",
		port or "no port",
		0, -- distance
		table.unpack(table.pack(...))
	}

	local datagram = ser.serialize(packed)
	return datagram .. '\n'
end

local function parsePacket(raw)
	assert(raw)
	local packed = ser.unserialize(raw)
	assert(packed ~= nil)
	assert(#packed >= 5)

	local packet = {}
	packet.type = packed[1]
	packet.target = packed[2]
	packet.source = packed[3]
	packet.port = packed[4]
	packet.distance = packed[5]
	packet.payload = {}

	for i=6,#packed do
		table.insert(packet.payload, packed[i])
	end

	return packet
end

local function packetToArray(packet)
	return
	{
		packet.type,
		packet.target,
		packet.source,
		packet.port,
		packet.distance,
		table.unpack(packet.payload)
	}
end

function modem_host.broadcast(packet)
	-- only host broadcasts
	-- this method will be hit for all broadcasted messages
	-- but nonhosting clients will simply not repeat the broadcast
	if modem_host.hosting then
		local plainArray = packetToArray(packet)
		local datagram = ser.serialize(plainArray)
		for addr,client in pairs(modem_host.clients) do
			client:send(datagram)
		end
	end
end

function modem_host.validTarget(target)
	if target == modem_host.id then
		return true
	end

	if not modem_host.hosting then
		return false
	end

	for address,client in pairs(modem_host.clients) do
		if address == target then
			return true
		end
	end

	return false
end

-- backend private methods, these are not pushed to user machine environments
function modem_host.pushMessage(target, datagram)
	if not modem_host.validTarget(target) then
		return false, "invalid target, no such client listening" --ignored
	end

	local packet = parsePacket(datagram)
	table.insert(modem_host.messages, packet)

	return true
end

function modem_host.processPendingMessages()
	modem_host.recvPendingMessages()

	-- computer address seems to be applied late
	if not modem_host.id then
		modem_host.id = component.list("computer",true)()
		assert(modem_host.id)
	end

	local i = 1;
	while i <= #modem_host.messages do
		local packet = modem_host.messages[i]
		local move = true

		if packet.type == 'modem_message' then

			-- broadcast if no target
			if packet.target == 0 then
				modem_host.broadcast(packet)
				-- clean up for broadcasting to self
				packet.target = modem_host.id
			end

			if packet.target == modem_host.id then
					if obj.isOpen(packet.port) then
    				table.insert(machine.signals, packetToArray(packet))
					end
				move = false
			end
		end

		if move then
			i = i + 1
		else
			table.remove(modem_host.messages, i)
		end
	end
end

function modem_host.recvPendingMessages()
	if modem_host.hosting then
		while 1 do
			local client = modem_host.socket:accept()
			if not client then
				break;
			end

			local handshakeDatagram, err = client:receive()
			if err then
				client:close()
			else
				client:settimeout(0, 't')

				local handshake = parsePacket(handshakeDatagram)
				modem_host.clients[handshake.source] = client
			end
		end

		-- recv all pending packets
		for source, client in pairs(modem_host.clients) do
			local line, err = client:receive()
			if not err then
				modem_host.pushMessage(source, line)
			end
		end
	elseif modem_host.socket then
		while 1 do
			local line, err = modem_host.socket:receive()
			if not err then
				modem_host.pushMessage(modem_host.id, line)
			else
				break
			end
		end
	end
end

function modem_host.createNewMessageBoard()
	local why
	modem_host.socket, why = socket.bind(modem_host.comms_ip, modem_host.comms_port)
	if modem_host.socket then
		modem_host.hosting = true
	end
	return modem_host.socket, why
end

function modem_host.joinExistingMessageBoard()
	local why
	modem_host.socket, why = socket.connect(modem_host.comms_ip, modem_host.comms_port)
	if modem_host.socket then
		modem_host.hosting = nil

		-- send handshake data
		local datagram = createPacket("client_handshake")
		modem_host.send(datagram)
	end
	return modem_host.socket, why
end

function modem_host.connectMessageBoard()
	if modem_host.connected then
		return true
	end

	local ok, reason = 
		modem_host.joinExistingMessageBoard() or
		modem_host.createNewMessageBoard()

	if not ok then
		return nil, reason
	end

	modem_host.socket:settimeout(0, 't') -- accept calls must be already pending
	modem_host.connected = true
	modem_host.clients = {}
	modem_host.messages = {}

	return true
end

function modem_host.send(datagram)
	-- if we are the host, we simply call pushMessage directly
	if modem_host.hosting then
		return modem_host.pushMessage(modem_host.id, datagram)
	else
		return not not modem_host.socket:send(datagram)
	end
end

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

function obj.send(address, port, ...) -- Sends the specified data to the specified target.
	cprint("modem.send",address, port, ...)
	compCheckArg(1,address,"string")
	compCheckArg(2,port,"number")
	port=checkPort(port)

	local datagram = createPacket("modem_message", address, port, ...)
	return modem_host.send(datagram)
end

function obj.getWakeMessage() -- Get the current wake-up message.
	cprint("modem.getWakeMessage")
	return wakeMessage
end

function obj.setWakeMessage(message) -- Set the wake-up message.
	cprint("modem.setWakeMessage",message)
	compCheckArg(1,message,"string","nil")
	wakeMessage = message
end

function obj.close(port) -- Closes the specified port (default: all ports). Returns true if ports were closed.
	cprint("modem.close",port)
	compCheckArg(1,port,"number","nil")
	if port ~= nil then
		port=checkPort(port)
	end

	if not obj.isOpen(port) then
		return false;
	end

	modem_host.open_ports[port] = nil
	return true
end

function obj.maxPacketSize() -- Gets the maximum packet size (config setting).
	cprint("modem.maxPacketSize")
	return settings.maxNetworkPacketSize
end

if wireless then
	function obj.getStrength() -- Get the signal strength (range) used when sending messages.
		cprint("modem.getStrength")
		return strength
	end
	function obj.setStrength(newstrength) -- Set the signal strength (range) used when sending messages.
		cprint("modem.setStrength",newstrength)
		compCheckArg(1,newstrength,"number")
		strength = newstrength
	end
end

function obj.isOpen(port) -- Whether the specified port is open.
	cprint("modem.isOpen",port)
	compCheckArg(1,port,"number")
	return modem_host.open_ports[port] ~= nil
end

function obj.open(port) -- Opens the specified port. Returns true if the port was opened.
	cprint("modem.open",port)
	compCheckArg(1,port,"number")
	port=checkPort(port)

	if obj.isOpen(port) then
		return false
	end

	-- make sure we are connected to the message board
	if not modem_host.connectMessageBoard() then
		return false
	end

	modem_host.open_ports[port] = true
	return true
end

function obj.isWireless() -- Whether this is a wireless network card.
	cprint("modem.isWireless")
	return wireless
end

function obj.broadcast(port, ...) -- Broadcasts the specified data on the specified port.
	cprint("modem.broadcast",port, ...)
	compCheckArg(1,port,"number")
	port=checkPort(port)

	-- we cannot broadcast unless we are connected to the message board
	if not modem_host.connectMessageBoard() then
		return false
	end

	local datagram = createPacket("modem_message", 0, port, ...)
	return modem_host.send(datagram)
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
