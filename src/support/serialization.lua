local serialization = {}

function serialization.serialize(value)
  local kw =  {["and"]=true, ["break"]=true, ["do"]=true, ["else"]=true,
               ["elseif"]=true, ["end"]=true, ["false"]=true, ["for"]=true,
               ["function"]=true, ["goto"]=true, ["if"]=true, ["in"]=true,
               ["local"]=true, ["nil"]=true, ["not"]=true, ["or"]=true,
               ["repeat"]=true, ["return"]=true, ["then"]=true, ["true"]=true,
               ["until"]=true, ["while"]=true}
  local id = "^[%a_][%w_]*$"
  local ts = {}
  local function s(v, l)
    local t = type(v)
    if t == "nil" then
      return "nil"
    elseif t == "boolean" then
      return v and "true" or "false"
    elseif t == "number" then
      if v ~= v then
        return "0/0"
      elseif v == math.huge then
        return "math.huge"
      elseif v == -math.huge then
        return "-math.huge"
      else
        return tostring(v)
      end
    elseif t == "string" then
      return string.format("%q", v):gsub("\\\n","\\n")
    elseif t == "table" then
      if ts[v] then
        error("tables with cycles are not supported")
      end
      ts[v] = true
      local i, r = 1, nil
      local f
      f = table.pack(pairs(v))
      for k, v in table.unpack(f) do
        if r then
          r = r .. ","
        else
          r = "{"
        end
        local tk = type(k)
        if tk == "number" and k == i then
          i = i + 1
          r = r .. s(v, l + 1)
        else
          if tk == "string" and not kw[k] and string.match(k, id) then
            r = r .. k
          else
            r = r .. "[" .. s(k, l + 1) .. "]"
          end
          r = r .. "=" .. s(v, l + 1)
        end
      end
      ts[v] = nil -- allow writing same table more than once
      return (r or "{") .. "}"
    else
      error("unsupported type: " .. t)
    end
  end
  local result = s(value, 1)
  return result
end

function serialization.unserialize(data)
  checkArg(1, data, "string")
  local result, reason = load("return " .. data, "=data", _, {math={huge=math.huge}})
  if not result then
    return nil, reason
  end
  local ok, output = pcall(result)
  if not ok then
    return nil, output
  end
  return output
end

-- This serialzier is bad, it is supposed to be bad. Don't use it.
function serialization.javaserialize(t)
	local tTracking = {}
	local function serializeImpl(t)
		local sType = type(t)
		if sType == "table" then
			if tTracking[t] ~= nil then
				return nil
			end
			tTracking[t] = true

			local result = "{"
			for k,v in pairs(t) do
				local cache1 = serializeImpl(k)
				local cache2 = serializeImpl(v)
				result = result..cache1.."="..cache2..", "
			end
			if result:sub(-2,-1) == ", " then result = result:sub(1,-3) end
			result = result.."}"
			return result
		elseif sType == "string" then
			return t
		elseif sType == "number" then
			if t == math.huge then
				return "Infinity"
			elseif t == -math.huge then
				return "-Infinity"
			elseif t ~= t then
				return "NaN"
			else
				return tostring(t):gsub("^[^e.]+%f[^0-9.]","%1.0"):gsub("e%+","e"):upper()
			end
		elseif sType == "boolean" then
			return tostring(t)
		else
			return string.format("%s@%x", "li.cil.repack.com.naef.jnlua.LuaState$LuaValueProxyImpl", math.random(0, 0xffffffff))
		end
	end
	return serializeImpl(t)
end

return serialization
