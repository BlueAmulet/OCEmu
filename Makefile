ASSETS=https://github.com/MightyPirates/OpenComputers/trunk/src/main/resources/assets/opencomputers

all: src/lua src/loot src/font.hex

src/lua:
	svn export $(ASSETS)/lua src/lua

src/loot:
	svn export $(ASSETS)/loot src/loot

src/font.hex:
	svn export $(ASSETS)/font.hex src/font.hex

clean:
	rm -rf src/lua
	rm -rf src/loot
	rm -f src/font.hex
