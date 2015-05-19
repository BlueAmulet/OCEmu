-- internet component
local obj = {}

function obj.isTcpEnabled() -- Returns whether TCP connections can be made (config setting).
	cprint("internet.isTcpEnabled")
	return config.get("internet.enableTcp",true)
end
function obj.isHttpEnabled() -- Returns whether HTTP requests can be made (config setting).
	cprint("internet.isHttpEnabled")
	return config.get("internet.enableHttp",true)
end
function obj.connect(address, port) -- Opens a new TCP connection. Returns the handle of the connection.
	--STUB
	cprint("internet.connect",address, port)
	if port == nil then port = -1 end
	compCheckArg(1,address,"string")
	compCheckArg(2,port,"number")
	if not config.get("internet.enableTcp",true) then
		return nil, "tcp connections are unavailable"
	end
	return nil
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
