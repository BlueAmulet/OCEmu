-- Welcome to hack town!
-- Patch luasocket's http library to be less stupid
local function gsub_escape(str)
    return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")..""
end
cprint("http_patch start")
-- Patch data
local patches = {
	{[[if headers[name] then headers[name] = headers[name] .. ", " .. value]],[[if headers[name] then if type(headers[name]) == "string" then headers[name] = {headers[name]} end headers[name][#headers[name]+1] = value]]},
	{[[local nreqt = adjustrequest(reqt)]],[[local nreqt = adjustrequest(reqt) if nreqt.scheme == "http" then nreqt.create = nil end]]},
	{[[_M.PORT = 80]],[[]]},
	{[[if nreqt.port == "" then nreqt.port = 80 end]],[[if nreqt.port == "" or nreqt.port == nil then if nreqt.scheme == "https" then nreqt.port = "443" else nreqt.port = "80" end end]]}
}
package.loaded["socket.http"] = nil
local path = package.searchpath("socket.http",package.path)
if path then
	local file, err = io.open(path,"rb")
	if not file then
		cprint("Failed to patch socket.http: " .. err)
		return
	end
	local data = file:read("*a")
	file:close()
	for i = 1,#patches do
		local newdata = data:gsub(gsub_escape(patches[i][1]), (patches[i][2]:gsub("%%","%%%%")..""))
		if newdata == data then
			cprint("Patch " .. i .. " failed")
		else
			data = newdata
		end
	end
	local fn, err = load(data,"="..path)
	if not fn then
		cprint("Failed to compile socket.http: " .. err)
		return
	end
	local ok, err = pcall(fn)
	if not ok then
		cprint("Failed to load socket.http: " .. err)
		return
	end
	package.loaded["socket.http"] = err
else
	cprint("Could not find socket.http")
end
cprint("http_patch end")
