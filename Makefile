PREFIX ?= ${HOME}/.config/lite-xl/plugins


all: build

lua:
	@$(MAKE) -C lib/lua linux install MYCFLAGS=-fPIC INSTALL_TOP="$(PWD)/build"

discord:
	cd lib/discord-rpc/ && \
	if [ ! -d "builds" ]; then \
		mkdir builds; \
	fi && \
	cd builds && \
	cmake .. -DCMAKE_INSTALL_PREFIX=. && \
	cmake --build  . --config Release && \
	make
	
	cp lib/discord-rpc/include/* include
	cp lib/discord-rpc/builds/src/libdiscord-rpc.a lib

build: lua discord
	@cp -r include build
	@cp lib/libdiscord-rpc.a build/lib

	g++ -fPIE -fPIC -Lbuild/lib -Ibuild/include discord.cpp -shared -o build/discord.so -ldiscord-rpc -pthread -llua
	cp test.lua build/
	cp init.lua build/
	@rm -rf build/bin build/include build/lib build/man build/share

clean:
	@echo cleaning
	@rm -rf build

	@$(MAKE) -C lib/lua clean
	@rm -rf lib/discord-rpc/builds

install: build
	@echo installing plugin to ${PREFIX}
	@rm -rf ${PREFIX}/lite-xl-discord
	@cp -r build ${PREFIX}/lite-xl-discord

uninstall:
	@echo removing plugin from ${PREFIX}
	@rm -rf ${PREFIX}/lite-xl-discord

.PHONY: all clean install uninstall
