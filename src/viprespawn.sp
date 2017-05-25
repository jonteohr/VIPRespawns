#include <sourcemod>
#include <colors>
#include <keyvalues>
#include <cstrike>

int Number;
int RespawnNumber[32];

ConVar g_cvNumber;

public Plugin myinfo = {
	name = "VIPRespawns",
	author = "BaroNN & Hypr",
	description = "Gives VIP players 3 respawns per map.",
	version = "1.1",
	url = "https://github.com/condolent/viprespawns"
};

public void OnPluginStart() {
	
	AutoExecConfig(true, "viprespawns");
	RegAdminCmd("sm_vipspawn", sm_vipspawn, ADMFLAG_RESERVATION);
	HookEvent("round_start", Event_Start);
	
	g_cvNumber = CreateConVar("respawn_amount", "3", "Amount of times a user is allowed to respawn per map");
	Number = g_cvNumber.IntValue;
	
}

public void OnConfigsExecuted() {
	
}

public Action sm_vipspawn(int client, int args) {
	
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	// Make sure client is alive
	if (!IsPlayerAlive(client)) {
		
		// Check how many times client has respawned
		if(RespawnNumber[client] < Number) {
			
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