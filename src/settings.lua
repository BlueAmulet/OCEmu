settings = {
	monochromeColor = tonumber(config.get("client.monochromeColor", "0xFFFFFF")),

	allowBytecode = config.get("computer.lua.allowBytecode",false),
	allowGC = config.get("computer.lua.allowGC",false),
	timeout = config.get("computer.timeout",5),

	components = config.get("emulator.components"),
	emulatorDebug = config.get("emulator.debug",true),
	vagueErrors = config.get("emulator.vague",true),

	httpEnabled = config.get("internet.enableHttp",true),
	tcpEnabled = config.get("internet.enableTcp",true),

	maxNetworkPacketSize = config.get("misc.maxNetworkPacketSize",8192),
	maxWirelessRange = config.get("misc.maxWirelessRange",400),
}

if settings.monochromeColor == nil then
	settings.monochromeColor = 0xFFFFFF
	config.set("client.monochromeColor", "0xFFFFFF")
end
