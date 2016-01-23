local address, _, wireless = ...
compCheckArg(1,wireless,"boolean")

local socket = require("socket")
local ser = require("loot.OpenOS.lib.serialization")

local function cerror(...)
	local args = table.pack(...)

	local sep = ''

	for _,arg in pairs(args) do
		local p;
		if (type(arg) == "userdata") then p = "userdata"
		elseif (type(arg) == "string") then p = arg
		else p = ser.serialize(arg) end
		io.stderr:write(sep .. tostring(_) .. '=' .. p)
		sep = ','
	end

	io.stderr:write('\n')
	io.stderr:flush()
end

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

function modem_host.createPacketArray(packetType, address, port, ...)
	compCheckArg(1,packetType,"string")
	compCheckArg(2,address,"string","number")
	compCheckArg(3,port,"number")

	local packed =
	{
		packetType,
		address,
		modem_host.id,
		port,
		0, -- distance
		...
	}

	return packed
end

function modem_host.packetArrayToPacket(packed)
	compCheckArg(1,packed,"table")
	assert(#packed >= 5)

	local packet = {}
	packet.type = packed[1]
	packet.target = packed[2]
	packet.source = packed[3]
	packet.port = packed[4]
	packet.distance = packed[5]
	packet.payload = {}

	-- all other keys will be index values but may skip some (nils)
	for k,v in pairs(packed) do
		if k > 5 then
			packet.payload[k-5] = v
		end
	end

	return packet
end

function modem_host.packetArrayToDatagram(packed)
	compCheckArg(1,packed,"table")

	local datagram = ser.serialize(packed)
	return datagram .. '\n'
end

function modem_host.packetToPacketArray(packet)
	local packed =
	{
		packet.type,
		packet.target,
		packet.source,
		packet.port,
		packet.distance,
	}

	if packet.payload then
		for i,v in pairs(packet.payload) do
			packed[i+5] = v
		end
	end

	return packed
end

function modem_host.datagramToPacketArray(datagram)
	compCheckArg(1,datagram,"string")
	return ser.unserialize(datagram)
end

function modem_host.datagramToPacket(datagram)
	return modem_host.packedToPacket(modem_host.datagramToPacketArray(datagram))
end

function modem_host.packetToDatagram(packet)
	return modem_host.packetArrayToDatagram(modem_host.packetToPacketArray(packet))
end

function modem_host.readDatagram(client) -- client:receive()
	local raw, err = client:receive()
	if raw then cerror("readDatagram", raw) end
	return raw, err
end

function modem_host.readPacketArray(client) -- client:receive()
	local datagram, err = modem_host.readDatagram(client)
	if datagram == nil then return nil, err end
	return modem_host.datagramToPacketArray(datagram)
end

function modem_host.readPacket(client) -- client:receive()
	local packed, err = modem_host.readPacketArray(client)
	if packed == nil then return nil, err end
	return modem_host.packetArrayToPacket(packed)
end

function modem_host.sendDatagram(client, datagram)
	cerror("sendDatagram", datagram)
	return client:send(datagram)
end

function modem_host.sendPacketArray(client, packed)
	local datagram = modem_host.packetArrayToDatagram(packed)
	return modem_host.sendDatagram(client, datagram)
end

function modem_host.sendPacket(client, packet)
	local datagram = modem_host.packetToDatagram(packet)
	return modem_host.sendDatagram(client, datagram)
end

function modem_host.broadcast(packet)
	-- we assume packet.target == 0
	if modem_host.hosting then
		for addr,client in pairs(modem_host.clients) do
			packet.target = addr
			modem_host.sendPacket(client, packet)
		end
		-- and self
		packet.target = modem_host.id
		modem_host.dispatchPacket(packet)
	else
		-- let host broadcast to all clients
		modem_host.sendPacket(modem_host.socket, packet)
	end
end

function modem_host.validTarget(target)
	if target ==  0 then
		return true -- broadcast
	end

	if target == modem_host.id then
		return true -- dispatch will add to machine signals
	end

	if not modem_host.hosting then
		return true -- dispatch can handle sending to host
	end

	for address,client in pairs(modem_host.clients) do
		if address == target then
			return true -- we are hosting and know about this target
		end
	end

	return false
end

-- backend private methods, these are not pushed to user machine environments
function modem_host.pushMessage(packet)
	if not modem_host.validTarget(packet.target) then
		return false, "invalid target, no such client listening" --ignored
	end

	table.insert(modem_host.messages, packet)

	return true
end

function modem_host.dispatchPacket(packet)
	if packet.target == modem_host.id then
		if obj.isOpen(packet.port) then
			table.insert(machine.signals, modem_host.packetToPacketArray(packet))
		end
	elseif modem_host.hosting then -- if hosting we will route
		for source,client in pairs(modem_host.clients) do
			if source == packet.target then
				modem_host.sendPacket(client, packet)
				break
			end
		end
	else -- not hosting, send to host
		modem_host.sendPacket(modem_host.socket, packet)
	end
end

function modem_host.processPendingMessages()
	-- do not try to process anything if this machine is not even connected to a message board
	-- not wrong without this, this is a simple optimization
	if not modem_host.connected then
		return
	end

	modem_host.acceptPendingClients()

	for _,packet in modem_host.allPendingMessages() do
		if packet.type == 'modem_message' then
			-- broadcast if no target
			if packet.target == 0 then
				modem_host.broadcast(packet)
			else
				modem_host.dispatchPacket(packet)
			end
		elseif packet.type == 'host_shutdown' then
			modem_host.host_shutdown = true
		end
	end
end

function modem_host.acceptPendingClients()
	if modem_host.hosting then
		while true do
			local client = modem_host.socket:accept()
			if client == nil then
				break;
			end

			local handshake, err = modem_host.readPacket(client) -- client:receive()
			if handshake == nil then
				client:close()
			else

				local connectionResponse
				local accepted = false
				if handshake.type ~= "handshake" then
					connectionResponse = modem_host.createPacketArray("handshake", 0, -1, 
						false, "unsupported message type");
				elseif modem_host.validTarget(handshake.source) then -- repeated client
					connectionResponse = modem_host.createPacketArray("handshake", 0, -1, 
						false, "computer address conflict detected, ignoring connection");
				else
					client:settimeout(0, 't')
					modem_host.clients[handshake.source] = client
					accepted = true

					connectionResponse = modem_host.createPacketArray("handshake", 0, -1, true);
				end

				modem_host.sendPacketArray(client, connectionResponse)

				if not accepted then
					client:close()
				end
			end
		end
	end
end

function modem_host.allPendingMessages()
	local msgIt = function(...)
		if #modem_host.messages > 0 then
			return 0, table.remove(modem_host.messages, 1)
		end

		if modem_host.hosting then
			for source, client in pairs(modem_host.clients) do
				local packet, err = modem_host.readPacket(client)
				if packet then
					return 0, packet
				elseif err ~= "timeout" then
					client:close()
					modem_host.clients[source] = nil
				end
			end
		elseif modem_host.socket then
			while true do
				local packet, err = modem_host.readPacket(modem_host.socket)
				if packet then
					return 0, packet
				else
					if err ~= "timeout" then
						if not modem_host.host_shutdown then
							error("modem host was unexpectedly lost")
						end
						modem_host.connected = false
						modem_host.connectMessageBoard()
					end
					break
				end
			end
		end
	end

	return msgIt, nil, 0
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
		local packed = modem_host.createPacketArray("handshake", 0, -1)
		local sendResult = modem_host.sendPacketArray(modem_host.socket, packed)

		local response, why = modem_host.readPacket(modem_host.socket)
		assert(response)
		assert(response.payload)

		if not response.payload[1] then
			modem_host.socket:close()
			modem_host.socket = nil
			return false, response.payload[2], true
		end
	end
	return modem_host.socket, why
end

function modem_host.connectMessageBoard()
	if modem_host.connected then
		return true
	end

	if modem_host.host_shutdown then
		modem_host.socket:close()
	end

	modem_host.socket = nil
	modem_host.clients = {}
	modem_host.messages = {}
	modem_host.host_shutdown = nil

	-- computer address seems to be applied late
	if modem_host.id == nil then
		modem_host.id = component.list("computer",true)()
		assert(modem_host.id)
	end

	local ok, info, critical = modem_host.joinExistingMessageBoard()

	if not ok and critical then
		return nil, info
	end

	if not ok then
		ok, info = modem_host.createNewMessageBoard()
	end

	if not ok then
		return nil, info
	end

	modem_host.socket:settimeout(0, 't') -- accept calls must be already pending
	modem_host.connected = true

	return true
end

function modem_host.halt(bReboot)
	compCheckArg(1,bReboot,"boolean")
	obj.close() -- close all virtual ports

	-- if only rebooting, pending messages don't need to be pumped and no one needs to be notified
	if modem_host.connected and not bReboot then

		if modem_host.hosting then
			for addr,csocket in pairs(modem_host.clients) do
				local notification = modem_host.createPacketArray("host_shutdown", addr, -1);
				modem_host.sendPacketArray(csocket, notification)
			end

			-- close all client connections
			for _,c in pairs(modem_host.clients) do
				c:close()
			end

			modem_host.hosting = false
			modem_host.clients = {} -- forget client socket data
		end

		-- close real port
		modem_host.socket:close()
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
	compCheckArg(1,address,"string")
	compCheckArg(2,port,"number")
	port=checkPort(port)

	-- we cannot send unless we are connected to the message board
	if not modem_host.connectMessageBoard() then
		return false
	end

	local packed = modem_host.createPacketArray("modem_message", address, port, ...)
	local packet = modem_host.packetArrayToPacket(packed)
	modem_host.pushMessage(packet)
	return true
end

function obj.getWakeMessage() -- Get the current wake-up message.
	return wakeMessage
end

function obj.setWakeMessage(message) -- Set the wake-up message.
	compCheckArg(1,message,"string","nil")
	wakeMessage = message
end

function obj.close(port) -- Closes the specified port (default: all ports). Returns true if ports were closed.
	compCheckArg(1,port,"number","nil")
	if port ~= nil then
		port=checkPort(port)
	end

	-- nil port case
	if port == nil then
		if not next(modem_host.open_ports) then
			return false, "no open ports"
		else
			modem_host.open_ports = {} -- close them all
		end
	elseif not obj.isOpen(port) then
		return false, "port not open"
	else
		modem_host.open_ports[port] = nil
	end

	return true
end

function obj.maxPacketSize() -- Gets the maximum packet size (config setting).
	return settings.maxNetworkPacketSize
end

if wireless then
	function obj.getStrength() -- Get the signal strength (range) used when sending messages.
		return strength
	end
	function obj.setStrength(newstrength) -- Set the signal strength (range) used when sending messages.
		compCheckArg(1,newstrength,"number")
		strength = newstrength
	end
end

function obj.isOpen(port) -- Whether the specified port is open.
	compCheckArg(1,port,"number")
	return modem_host.open_ports[port] ~= nil
end

function obj.open(port) -- Opens the specified port. Returns true if the port was opened.
	compCheckArg(1,port,"number")
	port=checkPort(port)

	if obj.isOpen(port) then
		return false, "port already open"
	end

	-- make sure we are connected to the message board
	local ok, why = modem_host.connectMessageBoard()
	
	if not ok then
		return false, why
	end

	modem_host.open_ports[port] = true
	return true
end

function obj.isWireless() -- Whether this is a wireless network card.
	return wireless
end

function obj.broadcast(port, ...) -- Broadcasts the specified data on the specified port.
	compCheckArg(1,port,"number")
	port=checkPort(port)

	-- we cannot broadcast unless we are connected to the message board
	if not modem_host.connectMessageBoard() then
		return false
	end

	local packed = modem_host.createPacketArray("modem_message", 0, port, ...)
	local packet = modem_host.packetArrayToPacket(packed)
	modem_host.pushMessage(packet)
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
