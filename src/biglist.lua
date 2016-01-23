local refs, whatlist, write, smallrefs

local function format(str)
	return '"'..str:gsub("[\n]","\\\n"):gsub("[^\n\32-\126][^0-9]", function(a) return "\\"..a:byte() end):gsub("[^\n\32-\126]", function(a) return "\\"..string.format("%03d",a:byte()) end)..'"'
end

local blacklist={thread=true,table=true,["function"]=true}
local function generalSort(a,b)
	local ta,tb = type(a),type(b)
	if ta == tb and not blacklist[ta] then
		return a < b
	end
	return tostring(ta) < tostring(tb)
end

local dump
function dump(obj, name, tabs, sort)
	if type(obj) == "table" then
		if refs[obj] then
			if #name < #refs[obj] then
				local oldname=refs[obj]
				refs[obj]=name
				for k,v in pairs(refs) do
					if v:sub(1,#oldname)==oldname then
						refs[k]=name..v:sub(#oldname+1)
					end
				end
			end
			write(0,"copy of "..refs[obj])
			return
		end
		if smallrefs then
			refs[obj]=smallrefs[obj] or name
		else
			refs[obj]=name
		end
		local keys={}
		for k in next, obj, nil do
			keys[#keys+1]=k
		end
		if #keys == 0 then
			write(0,"{}")
			return
		end
		write(0,"{\n")
		table.sort(keys,generalSort)
		for i=1,#keys do
			local k=keys[i]
			local v=rawget(obj, k)
			write(tabs+1,"[")
			local additional=""
			if type(k)=="function" or type(k)=="thread" then
				additional="("..type(k)..")"
			end
			dump(k, name.."[key:"..tostring(k)..additional.."]", tabs+1)
			write(0,"]=")
			if type(v)=="function" or type(v)=="thread" then
				additional="("..type(v)..")"
			end
			if (name:sub(-19)=="(function)][locals]" or name:sub(-21)=="(function)][upvalues]") and v=="(no value)" then
				write(0,v)
			else
				dump(v, name.."["..tostring(k)..additional.."]", tabs+1)
			end
			write(0,",\n")
		end
		write(tabs,"}")
		local meta=debug.getmetatable(obj)
		if meta then
			write(0,"\n")
			write(tabs,"(metatable)")
			dump(meta, name:sub(1,-2).."(metatable)]", tabs)
		end
	elseif type(obj) == "function" then
		if refs[obj] then
			if #name < #refs[obj] then
				local oldname=refs[obj]
				refs[obj]=name
				for k,v in pairs(refs) do
					if v:sub(1,#oldname)==oldname then
						refs[k]=name..v:sub(#oldname+1)
					end
				end
			end
			write(0,"copy of "..refs[obj])
			return
		end
		if smallrefs then
			refs[obj]=smallrefs[obj] or name
		else
			refs[obj]=name
		end
		if whatlist[obj] then
			refs[obj]="(Lua)"..whatlist[obj]
		end
		write(0,"(function)")
		local info=debug.getinfo(obj)
		if info.what=="C" and info.namewhat=="" then
			info.namewhat=whatlist[obj] or ""
		end
		local ok, fdump=pcall(string.dump, obj)
		if ok then
			info.size=#fdump
		end
		info.func=nil
		info.locals={}
		local i=1
		while true do
			local name, val=debug.getlocal(obj,i)
			if not name then break end
			if type(val)=="nil" then
				val="(no value)"
			end
			info.locals[name]=val
			i=i+1
		end
		info.upvalues={}
		i=1
		while true do
			local name, val=debug.getupvalue(obj,i)
			if not name then break end
			if type(val)=="nil" then
				val="(no value)"
			end
			info.upvalues[name]=val
			i=i+1
		end
		if info.source:sub(1,1)=="@" and info.source:sub(-4)==".lua" then
			info.upvalues=nil
			info.locals=nil
			info.secret="ocemu"
		end
		dump(info, name, tabs, true)
		refs[info]=nil
	elseif type(obj) == "thread" then
		if refs[obj] then
			if #name < #refs[obj] then
				local oldname=refs[obj]
				refs[obj]=name
				for k,v in pairs(refs) do
					if v:sub(1,#oldname)==oldname then
						refs[k]=name..v:sub(#oldname+1)
					end
				end
			end
			write(0,"copy of "..refs[obj])
			return
		end
		if smallrefs then
			refs[obj]=smallrefs[obj] or name
		else
			refs[obj]=name
		end
		write(0,"(thread){\n")
		local i=0
		while true do
			local ftbl=debug.getinfo(obj,i,"f")
			if not ftbl then break end
			write(tabs+1,"[level:"..i.."]=")
			dump(ftbl.func,name.."[level:"..i.."(function)]", tabs+1)
			write(0,",\n")
			i=i+1
		end
		write(tabs,"}")
	elseif type(obj) == "string" then
		write(0,format(obj))
	elseif type(obj) == "number" or type(obj) == "boolean" or type(obj) == "nil" then
		write(0,tostring(obj))
	else--if type(obj) == "userdata" then
		-- TODO: What to do about this?
		write(0,tostring(obj))
	--else
		--error("Unsupported type: "..type(obj))
	end
end

local biglist = {}

function biglist.dump(obj, name)
	refs, smallrefs={}
	whatlist={}
	for k,v in pairs(_ENV) do
		if type(v)=="function" and debug.getinfo(v).what=="C" then
			whatlist[v]=k
		elseif type(v)=="table" and v~=_G then
			for j,l in pairs(v) do
				if type(l)=="function" and debug.getinfo(l).what=="C" then
					whatlist[l]=k.."."..j
				end
			end
		end
	end
	function write() end
	dump(obj, name, 0)
	function write(tabs, msg)
		io.stdout:write(string.rep("\t",tabs)..tostring(msg))
	end
	smallrefs, refs=refs, {}
	for k,v in pairs(package.loaded) do
		refs[v]="package.loaded["..format(k).."]"
	end
	refs[_ENV]="Real Lua Environment"
	refs[package.loaded]="package.loaded"
	dump(obj, name, 0)
	
	io.stdout:flush()
end

return biglist
