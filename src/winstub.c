/* Just a small stub to assist with running OCEmu from Windows */
#include <stdlib.h>
#include <stdio.h>

#include <windows.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

void bail(lua_State *L) {
	MessageBox(NULL, lua_tostring(L, -1), "OCEmu Lua Error", MB_ICONERROR);
	exit(1);
}

int main(int argc, char *argv[]) {
	lua_State *L;

	if (AttachConsole(ATTACH_PARENT_PROCESS)) {
		freopen("CONOUT$", "w", stdout);
		freopen("CONOUT$", "w", stderr);
	}

	L = luaL_newstate();
	luaL_openlibs(L);
	if (luaL_loadfile(L, "boot.lua"))
		bail(L);
	for (int i = 1; i < argc; i++)
		lua_pushstring(L, argv[i]);
	if (lua_pcall(L, argc-1, 0, 0))
		bail(L);
	lua_close(L);

	return 0;
}