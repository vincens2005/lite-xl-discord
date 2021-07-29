default:
	if  test -d build ; then echo "build dir exists"; else mkdir build; fi
	g++ -Llib -Iinclude -c discord.c -o build/discord.o -ldiscord-rpc -pthread 
	g++ -pthread -Llib -Iinclude build/discord.o -shared -o build/discord.so -ldiscord-rpc
	rm build/discord.o
	cp test.lua build/
	cp init.lua build/

