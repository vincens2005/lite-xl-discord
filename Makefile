PREFIX ?= ${HOME}/.config/lite-xl/plugins


all: build

lua:
	@$(MAKE) -C lib/lua linux install MYCFLAGS=-fPIC INSTALL_TOP="$(PWD)/build"

build: lua
	@cp -r include build
	@cp lib/libdiscord-rpc.a build/lib

	g++ -Lbuild/lib -Ibuild/include discord.c -shared -o build/discord.so -ldiscord-rpc -pthread -llua
	cp test.lua build/
	cp init.lua build/
	cp fsutil.lua build/
	@rm -rf build/bin build/include build/lib build/man build/share

clean:
	@echo cleaning
	@rm -rf build

	@$(MAKE) -C lib/lua clean

install: build
	@echo installing plugin to ${PREFIX}
	@cp -r build ${PREFIX}/lite-xl-discord

uninstall:
	@echo removing plugin from ${PREFIX}
	@rm -rf ${PREFIX}/lite-xl-discord

.PHONY: all clean install uninstall
