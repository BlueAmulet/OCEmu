-- ocemu component

component.connect("filesystem",gen_uuid(),nil,"customlua/ocemu",true)

local obj = {}

function obj.connect(kind, address, slot, ...)
	cprint("screen.isTouchModeInverted")
	compCheckArg(1,kind,"string")
	compCheckArg(2,address,"string","number","nil")
	compCheckArg(3,slot,"number","nil")
	if address == nil then
		if elsa.SDL then
			math.randomseed(elsa.SDL.getTicks())
		else
			math.randomseed(os.clock()*1000000)
		end
		address=gen_uuid()
	end
	return component.connect(kind, address, slot, ...)
end
function obj.disconnect(address)
	checkArg(1,address,"string")
	return component.disconnect(address)
end

local cec = {}

local doc = {}

return obj,cec,doc
