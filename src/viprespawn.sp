#include <sourcemod>
#include <colors>
#include <cstrike>

#define Number 2
int RespawnNumber[32];

public Plugin myinfo = {
	name = "Respawn For VIPS",
	author = "BaroNN & Hypr",
	description = "Gives VIP players 3 respawns per map.",
	version = "1.0",
	url = "https://github.com/condolent/viprespawns"
};

public void OnPluginStart() {
	RegAdminCmd("sm_vipspawn", sm_vipspawn, ADMFLAG_RESERVATION);
	HookEvent("round_start", Event_Start);
}

public Action sm_vipspawn(int client, int args) {
	
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	// Make sure client is alive
	if (!IsPlayerAlive(client)) {
		
		// Check how many times client has respawned
		if(RespawnNumber[client] <= Number) {
			
			CS_RespawnPlayer(client);
			RespawnNumber[client] += 1;
			CPrintToChatAll("[{green}VIPRespawn{default}] %s used a Respawn!", name);
			
		} else {
			CPrintToChat(client, "[{green}VIPRespawn{default}] You have used all your respawns!");
		}
		
	} else {
		CPrintToChat(client, "[{green}VIPRespawn{default}] You cannot respawn when alive!");
	}
}

public Action Event_Start(Handle sEvent, const char[] Name, bool DontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(sEvent, "userid"));
	RespawnNumber[client] = 0;
}