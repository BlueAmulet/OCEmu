settings = {
	allowBytecode = config.get("computer.lua.allowBytecode",false),
	timeout = config.get("computer.timeout",5),

	components = config.get("emulator.components"),
	emulatorDebug = config.get("emulator.debug",true),

	httpEnabled = config.get("internet.enableHttp",true),
	tcpEnabled = config.get("internet.enableTcp",true),

	maxNetworkPacketSize = config.get("misc.maxNetworkPacketSize",8192),
	maxWirelessRange = config.get("misc.maxWirelessRange",400),
}
