#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

// sleep()
#ifdef _WIN32
#include <Windows.h>
#else
#include <unistd.h>
#endif

#include "discord_rpc.h"

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
	DiscordEventHandlers handlers;
	memset(&handlers, 0, sizeof(handlers));
	handlers.ready = discord_ready;
	handlers.disconnected = discord_disconnected;
	handlers.errored = discord_error;
	// handlers.joinGame = handleDiscordJoin;
	// handlers.spectateGame = handleDiscordSpectate;
	// handlers.joinRequest = handleDiscordJoinRequest;
	Discord_Initialize(APPLICATION_ID, &handlers, 1, NULL);
}


static void update_presence(char* state, char* details) {
	DiscordRichPresence discordPresence;
	memset(&discordPresence, 0, sizeof(discordPresence));
	discordPresence.state = state;
	discordPresence.details = details;
	discordPresence.startTimestamp = start_time;
	discordPresence.largeImageKey = "lite-xl";
	discordPresence.instance = 0;
	Discord_UpdatePresence(&discordPresence);
}

int main(int argc, char* argv[]) {
	init_discord();
	
	sleep(1);
	
	update_presence("this is a test", "for a C API");
	
	sleep(10);
	
	Discord_Shutdown();
	return 0;
}
