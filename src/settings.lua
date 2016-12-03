settings = {
	beepSampleRate = config.get("client.beepSampleRate", 44100),
	beepVolume = config.get("client.beepVolume", 32),
	monochromeColor = tonumber(config.get("client.monochromeColor", "0xFFFFFF")),

	allowBytecode = config.get("computer.lua.allowBytecode",false),
	allowGC = config.get("computer.lua.allowGC",false),
	timeout = config.get("computer.timeout",5),

	components = config.get("emulator.components"),
	emulatorDebug = config.get("emulator.debug",false),
	fast = config.get("emulator.fast",true),
	vagueErrors = config.get("emulator.vague",true),

	maxReadBuffer = config.get("filesystem.maxReadBuffer",2048),

	httpEnabled = config.get("internet.enableHttp",true),
	tcpEnabled = config.get("internet.enableTcp",true),

	maxNetworkPacketSize = config.get("misc.maxNetworkPacketSize",8192),
	maxWirelessRange = config.get("misc.maxWirelessRange",400),
}

if settings.monochromeColor == nil then
	settings.monochromeColor = 0xFFFFFF
	config.set("client.monochromeColor", "0xFFFFFF")
end
