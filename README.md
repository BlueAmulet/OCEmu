OCEmu - OpenComputers Emulator
==============================

# Features added compared to original
* 95% - (Optional) Filesystem size limitation
* 100% - Paste with mouse wheel
* TODO- Debugger mode. Useful for coding OSes
* TODO- Profiler
* TODO- Automatic unit tests

Installation
------------

Needs lua-5.2, luafilesystem, luautf8, luaffi, and SDL2.  
luasocket is optional but is required for the Internet Component and higher precision timing.  
luasec is optional but is required for HTTPS.

This git repository contains submodules, please clone using `git clone --recursive https://github.com/gamax92/OCEmu.git`

**Windows**

Binaries: [Windows 32bit](https://gamax92.keybase.pub/ocemu/OCEmu-x32.zip) and [Windows 64bit](https://gamax92.keybase.pub/ocemu/OCEmu-x64.zip) [(Build Date)](https://gamax92.keybase.pub/ocemu/builddate.txt)

The binaries above have everything pre compiled and packed up for ease of use.

If you'd like to compile OCEmu yourself for Windows, the provided script ```msys2_setup_ocemu.sh``` will automated the compiling process for Windows, run it inside of the [MSYS2](https://msys2.github.io/) environment.  
Ignore the **Lua Libraries** step as it doesn't work on Windows and the script does this for you.

**Ubuntu**
```
apt-get install lua5.2 liblua5.2-dev libsdl2-dev subversion
```
Install a versioned luarocks for 5.2 as described in: http://stackoverflow.com/a/20359102
```
# Download and unpack the latest luarocks from: http://luarocks.org/releases
./configure --lua-version=5.2 --lua-suffix=5.2 --versioned-rocks-dir
make build
sudo make install
```

Follow the luarocks steps below.

**Arch Linux**

Grab the Lua 5.2, luarocks5.2, lua52-filesystem, lua52-sec & lua52-socket from the official repos using Pacman.
```
pacman -S lua52 luarocks5.2 lua52-filesystem lua52-sec lua52-socket
```
Now follow the luarocks steps below to get the remaining libraries which are not on Arch's repos.


**Mac**

Mac users can get up and running quickly by using [brew](http://brew.sh/).

Brew installs luarocks as part of the lua package.
```
# Run this before the luarocks install steps below
brew install lua
brew install sdl2
```
Follow the luarocks steps below.

**Lua Libraries**
```
luarocks-5.2 install luafilesystem
luarocks-5.2 install luautf8
luarocks-5.2 install luasocket
luarocks-5.2 install luasec
cd luaffifb
luarocks-5.2 make

# OpenComputer's lua source code is not provided, if you have svn then use the provided Makefile
# If you hate svn, manually download assets/loot, assets/lua, and assets/font.hex into src/
```

Running
-------
Launch boot.lua with lua5.2, and provided everything is installed, you'll have a working Emulator.  
OCEmu stores its files in the following locations:

OS | Location
--- | ---
Windows | `%APPDATA%\\OCEmu`
Linux | `$XDG_CONFIG_HOME/ocemu` or `$HOME/.config/ocemu`

```
cd src
lua boot.lua
```

If you want to use a custom path (for example, for running multiple machines with unique filesystems) you can specify the machine path as an argument to boot.lua:

```
cd src
lua boot.lua /path/to/my/emulated/machine_a
```

## The fork on itself
The fork on itself is a update of the, now to seem, not working on project by gamax92. In this fork i'm going to try to fix all known bugs and to verify and add existing pull requests, and also treat issues on my own.
