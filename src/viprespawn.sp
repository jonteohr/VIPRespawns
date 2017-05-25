#include <sourcemod>
#include <colors>
#include <cstrike>

int Number;
int RespawnNumber[32];
int RespawnLeft;

ConVar g_cvNumber;
ConVar g_cvFlag;

public Plugin myinfo = {
	name = "VIPRespawns",
	author = "BaroNN & Hypr",
	description = "Gives VIP players some respawns per map.",
	version = "1.3",
	url = "https://github.com/condolent/viprespawns"
};

public void OnPluginStart() {
	
	g_cvFlag = CreateConVar("respawn_flag", "ADMFLAG_RESERVATION", "Users with this flag are allowed to use the respawn command.\n Correct flagnames needs to be used: http://bit.ly/2rkYezB");
	g_cvNumber = CreateConVar("respawn_amount", "3", "Amount of times a user is allowed to respawn per map");
	Number = g_cvNumber.IntValue;
	RespawnLeft = Number;
	
	AutoExecConfig(true, "viprespawns");
	RegAdminCmd("sm_vipspawn", sm_vipspawn, g_cvFlag.Flags);
	RegAdminCmd("sm_spawnsleft", sm_spawnsleft, g_cvFlag.Flags);
	HookEvent("round_start", Event_Start);
	
	
}

public Action sm_spawnsleft(int client, int args) {
	
	CPrintToChat(client, "[{green}VIPRespawn{default}] You have %d respawns left!", RespawnLeft);
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
			RespawnLeft -= 1;
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

public void OnConfigsExecuted() {
	
}