local args = { ... }
if #args ~= 1 then
	print("Usage: gencomp address")
	return
end
local component = require("component")
local address = component.get(args[1])
local proxy = component.proxy(address)
local direct = component.methods(address)
print(proxy.type)
local keys = {}
for k,v in pairs(proxy) do
	if type(v) == "table" then
		keys[#keys+1] = k
	end
end
table.sort(keys,function(a,b) return a:reverse() < b:reverse() end)
local file = io.open("list.txt","wb")
file = file:write("-- " .. proxy.type .. " component\nlocal mai = {}\nlocal obj = {}\n")
for i = 1,#keys do
	local k = keys[i]
	local doc = ""
	local comment
	if component.doc(address,k) ~= nil then
		doc = component.doc(address,k):match("%((.-)%)"):gsub("[%[%]]","") .. ","
		doc = doc:gsub("(.-):.-,",function(a) return a .. "," end):sub(1,-2)
		comment = component.doc(address,k)
	end
	file:write("\nmai." .. k .. " = {" .. (direct[k] and "direct = true, " or "") .. string.format("doc = %q}\n", comment))
	file:write("function obj." .. k .. "(" .. doc .. ")\n\t--STUB\n\tcprint(\"" .. proxy.type .. "." .. k .. "\"" .. (doc ~= "" and ", " or "") .. doc .. ")\nend\n")
end
file:write("\nreturn obj,nil,mai")
file:close()
