
--- Stricter version of compat52.
-- Attempts to emulate Lua 5.2 when built without LUA_COMPAT_ALL.


if _VERSION == "Lua 5.1" then

   require("compat52")

   local function not_available()
      error("This function is not available in Lua 5.2!", 2)
   end

   local exclude_from_G = {
      module = not_available,
      getfenv = not_available,
      setfenv = not_available,
      loadstring = not_available,
      unpack = not_available,
      loadlib = not_available,
      math = {
         log10 = not_available,
         mod = not_available,
      },
      table = {
         getn = not_available,
         setn = not_available,
      },
      string = {
         gfind = not_available,
      },
   }

   local next = next
   local function make_pairs_iterator(lookup)
      return function(st, var)
         local k, v = next(st, var)
         if k ~= nil then
            local new_v = lookup[k]
            if new_v ~= nil then v = new_v end
            return k, v
         end
      end
   end

   local rawget = rawget
   local function make_ipairs_iterator(lookup)
      return function(st, var)
         var = var + 1
         local v = rawget(st, var)
         if v ~= nil then
            local new_v = lookup[var]
            if new_v ~= nil then v = new_v end
            return var, v
         end
      end
   end

   local function make_copy(value, excl)
      local v_type, e_type = type(value), type(excl)
      if v_type == e_type then
         if v_type == "table" then
            local l_table = {}
            for k, v in pairs(excl) do
               l_table[k] = make_copy(rawget(value, k), v)
            end
            local pairs_iterator = make_pairs_iterator(l_table)
            local ipairs_iterator = make_ipairs_iterator(l_table)
            return setmetatable({}, {
               __index = function(_, k)
                  local v = l_table[k]
                  if v ~= nil then
                     return v
                  else
                     return value[k]
                  end
               end,
               __newindex = function(_, k, v)
                  if l_table[k] ~= nil then
                     l_table[k] = nil
                  end
                  value[k] = v
               end,
               __pairs = function()
                  return pairs_iterator, value, nil
               end,
               __ipairs = function()
                  return ipairs_iterator, value, 0
               end,
            }), l_table
         elseif v_type == "function" then
            return excl
         end
      end
   end

   local new_G, G_lookup = make_copy(_G, exclude_from_G)
   G_lookup._G = new_G

   return function()
      setfenv(2, new_G)
   end
else
   return function() end
end

-- vi: set expandtab softtabstop=3 shiftwidth=3 :
