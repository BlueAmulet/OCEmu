ASSETS=https://github.com/MightyPirates/OpenComputers/trunk/src/main/resources/assets/opencomputers

all: src/lua src/loot src/unifont.hex ocemu2d

src/lua:
	svn export $(ASSETS)/lua src/lua

src/loot:
	svn export $(ASSETS)/loot src/loot

src/unifont.hex:
	svn export $(ASSETS)/unifont.hex src/unifont.hex
	
ocemu2d:
	cd src; zip -r -9 ../ocemu2d.love *; cd ..

clean:
	rm -f ocemu2d.love
	rm -rf src/lua
	rm -rf src/loot
	rm -f src/unifont.hex
