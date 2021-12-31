#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

//#include "lua.hpp"
extern "C" {
	#include "lite_xl_plugin_api.h"
}

#include "discord_rpc.h"

static lua_State *L;
static int ready_cb, disconnect_cb, error_cb;

static void discord_ready(const DiscordUser* connectedUser) {
	lua_rawgeti(L, LUA_REGISTRYINDEX, ready_cb);
	if (lua_isfunction(L, -1)) {
		lua_newtable(L);
		lua_pushstring(L, connectedUser->userId);
		lua_setfield(L, -2, "user_id");
		lua_pushstring(L, connectedUser->username);
		lua_setfield(L, -2, "username");
		lua_pushstring(L, connectedUser->discriminator);
		lua_setfield(L, -2, "discriminator");
		lua_pushstring(L, connectedUser->avatar);
		lua_setfield(L, -2, "avatar");
		
		lua_call(L, 1, 0);
	}
}

static void discord_disconnected(int errcode, const char* message) {
	lua_rawgeti(L, LUA_REGISTRYINDEX, disconnect_cb);
	if (lua_isfunction(L, -1)) {
		lua_pushnumber(L, errcode);
		lua_pushstring(L, message);
		
		lua_call(L, 2, 0);
	}
}

static void discord_error(int errcode, const char* message) {
	lua_rawgeti(L, LUA_REGISTRYINDEX, error_cb);
	if (lua_isfunction(L, -1)) {
		lua_pushnumber(L, errcode);
		lua_pushstring(L, message);
		
		lua_call(L, 2, 0);
	}
}

static int f_init(lua_State *L) {
	const char *application_id = luaL_checkstring(L, 1);

	DiscordEventHandlers handlers;
	memset(&handlers, 0, sizeof(handlers));
	handlers.ready = discord_ready;
	handlers.disconnected = discord_disconnected;
	handlers.errored = discord_error;
	Discord_Initialize(application_id, &handlers, 1, NULL);

	return 0;
}

#define L_GETSTR(L, n, k, d) (lua_getfield(L, n, k), luaL_optstring(L, -1, d))
#define L_GETINT(L, n, k, d) (lua_getfield(L, n, k), luaL_optnumber(L, -1, d));
static int f_update(lua_State *L) {
	DiscordRichPresence presence;
	memset(&presence, 0, sizeof(presence));

	luaL_checktype(L, 1, LUA_TTABLE);
	presence.state = L_GETSTR(L, 1, "state", NULL);
	presence.details = L_GETSTR(L, 1, "details", NULL);
	presence.startTimestamp = L_GETINT(L, 1, "start_time", 0);
	presence.endTimestamp = L_GETINT(L, 1, "end_time", 0);
	presence.largeImageKey = L_GETSTR(L, 1, "large_image", NULL);
	presence.largeImageText = L_GETSTR(L, 1, "large_image_text", NULL);
	presence.smallImageKey = L_GETSTR(L, 1, "small_image", NULL);
	presence.smallImageText = L_GETSTR(L, 1, "small_image_text", NULL);
	lua_pop(L, 8);

	Discord_UpdatePresence(&presence);
	return 0;
}

static int f_clear(lua_State *L) {
	Discord_ClearPresence();
	return 0;
}

static int f_shutdown(lua_State *L) {
	Discord_Shutdown();
	return 0;
}

static int f_poll(lua_State *L) {
	Discord_RunCallbacks();
	return 0;
}

static const char *ev_enum[] = {
	"ready",
	"disconnect",
	"error",
	NULL
};

static int f_on_event(lua_State *L) {
	int cb = luaL_checkoption(L, 1, NULL, ev_enum);
	luaL_checkany(L, 2);
	lua_pushvalue(L, 2);

	switch (cb) {
		case 0:
			ready_cb = luaL_ref(L, LUA_REGISTRYINDEX);
			break;
		case 1:
			disconnect_cb = luaL_ref(L, LUA_REGISTRYINDEX);
			break;
		case 2:
			error_cb = luaL_ref(L, LUA_REGISTRYINDEX);
	}
	return 0;
}

static const struct luaL_Reg lib[] = {
	{"init",     f_init},
	{"update",   f_update},
	{"poll",     f_poll},
	{"shutdown", f_shutdown},
	{"clear",    f_clear},
	{"on_event", f_on_event},
	{NULL, NULL}
};

extern "C" {
	int luaopen_lite_xl_discord(lua_State *state, void *XL) {
		lite_xl_plugin_init(XL);
		L = state;
		luaL_newlib(L, lib);
		return 1;
	}
}
