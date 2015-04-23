ASSETS=https://github.com/MightyPirates/OpenComputers/trunk/src/main/resources/assets/opencomputers

all: src/lua src/loot src/unifont.hex

src/lua:
	svn export $(ASSETS)/lua src/lua

src/loot:
	svn export $(ASSETS)/loot src/loot

src/unifont.hex:
	svn export $(ASSETS)/unifont.hex src/unifont.hex

clean:
	rm -rf src/lua
	rm -rf src/loot
	rm -f src/unifont.hex
