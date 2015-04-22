
--- Stricter version of compat52.
-- Attempts to emulate Lua 5.2 when built without LUA_COMPAT_ALL.

require("compat52")

if _VERSION == "Lua 5.1" then

   module = nil
   setfenv = nil
   getfenv = nil
   math.log10 = nil
   loadstring = nil
   table.maxn = nil
   unpack = nil
   -- functions deprecated in Lua 5.1 are also not available:
   table.getn = nil
   table.setn = nil
   loadlib = nil
   math.mod = nil
   string.gfind = nil

end
