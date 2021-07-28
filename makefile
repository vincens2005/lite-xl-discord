default:
	g++ -no-pie -Llib -Iinclude discord.c -o build/discord -ldiscord-rpc -pthread
