#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#include "discord_rpc.h"

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
}

static const char* APPLICATION_ID = "839231973289492541";
static int64_t start_time;

// stolen from discord api example (im bad at c)
// handlers
static void discord_ready(const DiscordUser* connectedUser) {
	printf("\ndiscord: connected to user %s#%s - %s\n",
					connectedUser->username,
					connectedUser->discriminator,
					connectedUser->userId);
}

static void discord_disconnected(int errcode, const char* message) {
	printf("\nDiscord: disconnected (%d: %s)\n", errcode, message);
}

static void discord_error(int errcode, const char* message) {
	printf("\nDiscord: error (%d: %s)\n", errcode, message);
}

static void init_discord() {
	start_time = time(0);
	printf("\nstarting rpc... \n");
	DiscordEventHandlers handlers;
	memset(&handlers, 0, sizeof(handlers));
	handlers.ready = discord_ready;
	handlers.disconnected = discord_disconnected;
	handlers.errored = discord_error;
	// handlers.joinGame = handleDiscordJoin;
	// handlers.spectateGame = handleDiscordSpectate;
	// handlers.joinRequest = handleDiscordJoinRequest;
	Discord_Initialize(APPLICATION_ID, &handlers, 1, NULL);
	printf("\nrpc started.\n");
}


static void update_presence(const char* state, const char* details, const char* large_image) {
	DiscordRichPresence discordPresence;
	memset(&discordPresence, 0, sizeof(discordPresence));
	discordPresence.state = state;
	discordPresence.details = details;
	discordPresence.startTimestamp = start_time;
	discordPresence.largeImageKey = large_image;
	discordPresence.instance = 0;
	Discord_UpdatePresence(&discordPresence);
}

// lua wrappers
extern "C" {
	static int lua_update_presence(lua_State* L) {
		const char* state = lua_tolstring(L, 1, NULL);
		const char* details = lua_tolstring(L, 2, NULL);
		const char* large_image = lua_tolstring(L, 3, NULL);
		update_presence(state, details, large_image);
		lua_pushnil(L);
		return 1;
	}
	
	static int lua_init_presence(lua_State* L) {
		init_discord();
		lua_pushnil(L);
		return 1;
	}
	
	static int lua_shutdown(lua_State* L) {
		Discord_Shutdown();
		lua_pushnil(L);
		return 1;
	}
	
	int luaopen_discord(lua_State* L) {
		static const struct luaL_Reg libs [] = {
					{"discord_update", lua_update_presence},
					{"discord_init", lua_init_presence},
					{"discord_shutdown", lua_shutdown},
					{NULL, NULL}
		};
		
		for (int i = 0; libs[i].name; i++) {
			lua_register(L, libs[i].name, libs[i].func);
		}
		return 1;
	}
}
