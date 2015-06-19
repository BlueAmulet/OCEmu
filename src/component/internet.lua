-- internet component

local okay, socket = pcall(require, "socket")
if not okay then
	cprint("Cannot use internet component: " .. socket)
	return
end
local url = require("socket.url")

component.connect("filesystem",gen_uuid(),nil,"lua/component/internet",true)

local obj = {}

local function checkUri(address, port)
	local parsed = url.parse(address)
	if parsed ~= nil and parsed.host ~= nil and (parsed.port ~= nil or port > -1) then
		return parsed.host, parsed.port or port
	end
	local simple = url.parse("oc://" .. address)
	if simple ~= nil and simple.host ~= nil and (simple.port ~= nil or port > -1) then
		return simple.host, simple.port or port
	end
	error("address could not be parsed or no valid port given",4)
end

function obj.isTcpEnabled() -- Returns whether TCP connections can be made (config setting).
	cprint("internet.isTcpEnabled")
	return config.get("internet.enableTcp",true)
end
function obj.isHttpEnabled() -- Returns whether HTTP requests can be made (config setting).
	cprint("internet.isHttpEnabled")
	return config.get("internet.enableHttp",true)
end
function obj.connect(address, port) -- Opens a new TCP connection. Returns the handle of the connection.
	cprint("internet.connect",address, port)
	if port == nil then port = -1 end
	compCheckArg(1,address,"string")
	compCheckArg(2,port,"number")
	if not config.get("internet.enableTcp",true) then
		return nil, "tcp connections are unavailable"
	end
	-- TODO Check for too many connections
	local host, port = checkUri(address, port)
	if host == nil then
		return host, port
	end
	local client = socket.tcp()
	-- TODO: not OC behaviour, but needed to prevent hanging
	client:settimeout(10)
	local connected = false
	local function connect()
		cprint("(socket) connect",host,port)
		local did, err = client:connect(host,port)
		cprint("(socket) connect results",did,err)
		if did then
			connected = true
			client:settimeout(0)
		end
	end
	local fakesocket = {
		read = function(n)
			cprint("(socket) read",n)
			-- TODO: Error handling
			if not connected then connect() return "" end
			if type(n) ~= "number" then n = math.huge end
			local data, err, part = client:receive(n)
			if err == nil or err == "timeout" or part ~= "" then
				return data or part
			else
				return nil, err
			end
		end,
		write = function(data)
			cprint("(socket) write",data)
			if not connected then connect() return 0 end
			checkArg(1,data,"string")
			local data, err, part = client:send(data)
			if err == nil or err == "timeout" or part ~= 0 then
				return data or part
			else
				return nil, err
			end
		end,
		close = function()
			cprint("(socket) close")
			pcall(client.close,client)
		end,
		finishConnect = function()
			cprint("(socket) finishConnect")
			-- TODO: Does this actually error?
			return connected
		end
	}
	return fakesocket
end
function obj.request(url, postData) -- Starts an HTTP request. If this returns true, further results will be pushed using `http_response` signals.
	--STUB
	cprint("internet.request",url, postData)
	compCheckArg(1,url,"string")
	if not config.get("internet.enableHttp",true) then
		return nil, "http requests are unavailable"
	end
	local post
	if type(postData) == "string" then
		post = postData
	end
	return nil
end

local cec = {}

local doc = {
	["isTcpEnabled"]="function():boolean -- Returns whether TCP connections can be made (config setting).",
	["isHttpEnabled"]="function():boolean -- Returns whether HTTP requests can be made (config setting).",
	["connect"]="function(address:string[, port:number]):userdata -- Opens a new TCP connection. Returns the handle of the connection.",
	["request"]="function(url:string[, postData:string]):userdata -- Starts an HTTP request. If this returns true, further results will be pushed using `http_response` signals.",
}

return obj,cec,doc
