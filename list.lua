local args = { ... }
if #args ~= 1 then
	return
end
local component = require("component")
local address = component.get(args[1])
local proxy = component.proxy(address)
print(proxy.type)
local keys = {}
for k,v in pairs(proxy) do
	if type(v) == "table" then
		keys[#keys+1] = k
	end
end
table.sort(keys,function(a,b) return a:reverse() < b:reverse() end)
local file = io.open("list.txt","wb")
file = file:write("-- " .. proxy.type .. " component\nlocal obj = {}\n\n")
for i = 1,#keys do
	local k = keys[i]
	local doc = ""
	local comment = "-- no doc"
	if component.doc(address,k) ~= nil then
		doc = component.doc(address,k):match("%((.-)%)"):gsub("[%[%]]","") .. ","
		doc = doc:gsub("(.-):.-,",function(a) return a .. "," end):sub(1,-2)
		comment = component.doc(address,k):match("%-%-.*")
	end
	file:write("function obj." .. k .. "(" .. doc .. ") " .. comment .."\n\t--STUB\n\tcprint(\"" .. proxy.type .. "." .. k .. "\"" .. (doc ~= "" and "," or "") .. doc .. ")\nend\n")
end
file:write("\nlocal cec = {}\n\nlocal doc = {\n")
for i = 1,#keys do
	local k = keys[i]
	if component.doc(address,k) ~= nil then
		local doc = component.doc(address,k)
		file:write(string.format("\t[%q]=%q,\n",k,doc))
	end
end
file:write("}\n\nreturn obj,cec,doc")
file:close()
