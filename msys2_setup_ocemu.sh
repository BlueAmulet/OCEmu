#!/bin/bash
MACHINE_TYPE=`uname -m`
pacman --needed --noconfirm -S mingw-w64-${MACHINE_TYPE}-toolchain winpty patch make git subversion mingw-w64-${MACHINE_TYPE}-SDL2
mkdir mingw-w64-lua
cd mingw-w64-lua
curl -L https://github.com/Alexpux/MINGW-packages/raw/541d0da31a4d2e648689655e49ddfffbe7ff5dfe/mingw-w64-lua/PKGBUILD -o PKGBUILD
curl -L https://github.com/Alexpux/MINGW-packages/raw/541d0da31a4d2e648689655e49ddfffbe7ff5dfe/mingw-w64-lua/implib.patch -o implib.patch
curl -L https://github.com/Alexpux/MINGW-packages/raw/541d0da31a4d2e648689655e49ddfffbe7ff5dfe/mingw-w64-lua/lua.pc -o lua.pc
curl -L https://github.com/Alexpux/MINGW-packages/raw/541d0da31a4d2e648689655e49ddfffbe7ff5dfe/mingw-w64-lua/searchpath.patch -o searchpath.patch
makepkg-mingw
if [ ! -e mingw-w64-${MACHINE_TYPE}-lua-5.2.4-1-any.pkg.tar.xz ]; then
	echo "Failed to build lua"
	exit 1
fi
pacman --noconfirm -U mingw-w64-${MACHINE_TYPE}-lua-5.2.4-1-any.pkg.tar.xz
cd ..
rm -r mingw-w64-lua
mkdir extras
cd extras
git clone -b v_1_6_3 --depth=1 https://github.com/keplerproject/luafilesystem.git
if [ ! -e luafilesystem ]; then
	echo "Failed to download luafilesystem"
	exit 1
fi
cd luafilesystem
cat << 'EOF' > lfs_mingw.patch
--- Makefile-old	2015-06-27 10:27:22.594787200 -0600
+++ Makefile	2015-06-27 10:27:32.306801800 -0600
@@ -12 +12 @@
-lib: src/lfs.so
+lib: src/lfs.dll
@@ -14,2 +14,2 @@
-src/lfs.so: $(OBJS)
-	MACOSX_DEPLOYMENT_TARGET="10.3"; export MACOSX_DEPLOYMENT_TARGET; $(CC) $(CFLAGS) $(LIB_OPTION) -o src/lfs.so $(OBJS)
+src/lfs.dll: $(OBJS)
+	MACOSX_DEPLOYMENT_TARGET="10.3"; export MACOSX_DEPLOYMENT_TARGET; $(CC) $(CFLAGS) $(LIB_OPTION) -o src/lfs.dll $(OBJS) -llua
@@ -18 +18 @@
-	LUA_CPATH=./src/?.so lua tests/test.lua
+	LUA_CPATH=./src/?.dll lua tests/test.lua
@@ -22 +22 @@
-	cp src/lfs.so $(LUA_LIBDIR)
+	cp src/lfs.dll $(LUA_LIBDIR)
@@ -25 +25 @@
-	rm -f src/lfs.so $(OBJS)
+	rm -f src/lfs.dll $(OBJS)
EOF
patch < lfs_mingw.patch
make
if [ ! -e src/lfs.dll ]; then
	echo "Failed to build luafilesystem"
	exit 1
fi
mv src/lfs.dll ..
cd ..
rm -r luafilesystem
git clone -b 0.1.1 --depth=1 https://github.com/starwing/luautf8.git
if [ ! -e luautf8 ]; then
	echo "Failed to download luautf8"
	exit 1
fi
cd luautf8
gcc -O2 -c -o lutf8lib.o lutf8lib.c
gcc -O -shared -o utf8.dll lutf8lib.o -llua
if [ ! -e utf8.dll ]; then
	echo "Failed to build luautf8"
	exit 1
fi
mv utf8.dll ..
cd ..
rm -r luautf8
git clone --depth=1 https://github.com/gamax92/luaffi.git
if [ ! -e luaffi ]; then
	echo "Failed to download luaffi"
	exit 1
fi
cd luaffi
cat << 'EOF' > luaffi_mingw.patch
--- Makefile-old	2015-06-27 10:41:00.288971000 -0600
+++ Makefile.win	2015-06-27 10:41:18.062998000 -0600
@@ -6,2 +6,3 @@
-LUA_CFLAGS=`$(PKG_CONFIG) --cflags lua5.2 2>/dev/null || $(PKG_CONFIG) --cflags lua`
-SOCFLAGS=`$(PKG_CONFIG) --libs lua5.2 2>/dev/null || $(PKG_CONFIG) --libs lua`
+LUA_CFLAGS=
+SOCFLAGS=-llua
+CC=gcc
EOF
patch < luaffi_mingw.patch
make -f Makefile.win ffi.dll
if [ ! -e ffi.dll ]; then
	echo "Failed to build luaffi"
	exit 1
fi
mv ffi.dll ..
cd ..
rm -r luaffi
git clone -b v3.0-rc1 --depth=1 https://github.com/diegonehab/luasocket.git
if [ ! -e luasocket ]; then
	echo "Failed to download luasocket"
	exit 1
fi
cd luasocket
LUALIB_mingw=-llua LUAV=5.2 make mingw
if [ ! -e src/mime.dll.1.0.3 ]; then
	echo "Failed to build luasocket"
	exit 1
fi
prefix=../.. PLAT=mingw CDIR_mingw= LDIR_mingw= make install
cd ..
rm -r luasocket
git clone -b luasec-0.5 --depth=1 https://github.com/brunoos/luasec.git
if [ ! -e luasec ]; then
	echo "Failed to download luasec"
	exit 1
fi
cd luasec
cat << 'EOF' > luasec_mingw.patch
--- src/luasocket/Makefile-old	2015-06-27 11:28:34.279159900 -0600
+++ src/luasocket/Makefile	2015-06-27 11:31:17.381422000 -0600
@@ -5 +5 @@
- usocket.o
+ wsocket.o
@@ -26 +26 @@
-usocket.o: usocket.c socket.h io.h timeout.h usocket.h
+wsocket.o: wsocket.c socket.h io.h timeout.h wsocket.h
--- src/Makefile-old	2015-06-27 11:54:34.670465000 -0600
+++ src/Makefile	2015-06-27 11:54:42.310475600 -0600
@@ -1 +1 @@
-CMOD=ssl.so
+CMOD=ssl.dll
@@ -53 +53 @@
-	$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)
+	$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LIBS) -llua -lws2_32
EOF
patch -p0 < luasec_mingw.patch
LD=gcc CC=gcc make linux
if [ ! -e src/ssl.dll ]; then
	echo "Failed to build luasec"
	exit 1
fi
DESTDIR=../.. LUAPATH= LUACPATH= make install
cd ..
rm -r luasec
cd ..
echo "Built everything!"