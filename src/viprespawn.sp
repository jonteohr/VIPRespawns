#include <sourcemod>
#include <colors>
#include <cstrike>

#define CHOICE1 "#choice1"
#define CHOICE2 "#choice2"

int Number;
int RespawnNumber[32];
int RespawnLeft;

ConVar g_cvNumber;
ConVar g_cvFlag;
ConVar g_cvMenu;

public Plugin myinfo = {
	name = "VIPRespawns",
	author = "BaroNN & Hypr",
	description = "Gives VIP players some respawns per map.",
	version = "1.4",
	url = "https://github.com/condolent/viprespawns"
};

public void OnPluginStart() {
	
	g_cvFlag = CreateConVar("respawn_flag", "ADMFLAG_RESERVATION", "Users with this flag are allowed to use the respawn command.\n Correct flagnames needs to be used: http://bit.ly/2rFMTtW");
	g_cvNumber = CreateConVar("respawn_amount", "3", "Amount of times a user is allowed to respawn per map");
	g_cvMenu = CreateConVar("enable_vip_menu", "1", "Enable the VIP-menu called with !vip?\n(0 = Disable, 1 = Enable)", _, true, 0.0, true, 1.0);
	Number = g_cvNumber.IntValue;
	RespawnLeft = Number;
	
	AutoExecConfig(true, "viprespawns");
	RegAdminCmd("sm_vipspawn", sm_vipspawn, g_cvFlag.Flags);
	RegAdminCmd("sm_spawnsleft", sm_spawnsleft, g_cvFlag.Flags);
	HookEvent("round_start", Event_Start);
	
	// Menu
	if(g_cvMenu.IntValue == 1) {
		RegAdminCmd("sm_vip", sm_vip, g_cvFlag.Flags);
	} else {
		PrintToServer("Someone tried opening the VIP-menu, but it's disabled in the config!");
	}
}

// !vip
public Action sm_vip(int client, int args) {
	
	char buff[128];
	Format(buff, sizeof(buff), "Respawns left: %d", RespawnLeft);
	
	Menu menu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	menu.SetTitle("VIP Menu");
	menu.AddItem(CHOICE1, "Respawn");
	menu.AddItem(CHOICE2, buff, ITEMDRAW_DISABLED);
	menu.Display(client, 20);
	
	return Plugin_Handled;
	
}

public int MenuHandler1(Menu menu, MenuAction action, int client, int param2) {
	
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	switch(action) {
		
		case MenuAction_Start:
		{
			//CPrintToChat(client, "[{green}VIPRespawns{default}] Opening menu...");
		}
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "VIP Menu", client);
			
			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
			//CPrintToChat(client, "[{green}VIPRespawns{default}] Client %d was sent menu with panel %x", name, param2);
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if(StrEqual(info, CHOICE1)) {
				// Just make sure player is alive
				if(!IsPlayerAlive(client)) {
					// Has player reached the respawn limit? If not, execute!
					if(RespawnNumber[client] < Number) {
						CS_RespawnPlayer(client);
						RespawnNumber[client] += 1;
						RespawnLeft -= 1;
						CPrintToChatAll("[{green}VIPRespawns{default}] %s used a Respawn!", name);	
					} else {
						CPrintToChat(client, "[{green}VIPRespawns{default}] You have used all your respawns!");
					}
				} else {
					CPrintToChat(client, "[{green}VIPRespawns{default}] You cannot respawn when alive!");
				}
			} else {
				// Print to server console if someone actually managed to select this option somehow.. (Debugging purposes)
				PrintToServer("Client %d selected %s even though it's disabled..", name, info);
			}
		}
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
			
			if(StrEqual(info, CHOICE2)) {
				return ITEMDRAW_DISABLED;
			} else {
				return style;
			}
		}
		
	}
	return 0;
}

public Action sm_spawnsleft(int client, int args) {
	
	CPrintToChat(client, "[{green}VIPRespawns{default}] You have %d respawns left!", RespawnLeft);
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
			CPrintToChatAll("[{green}VIPRespawns{default}] %s used a Respawn!", name);
			
		} else {
			CPrintToChat(client, "[{green}VIPRespawns{default}] You have used all your respawns!");
		}
		
	} else {
		CPrintToChat(client, "[{green}VIPRespawns{default}] You cannot respawn when alive!");
	}
}

public Action Event_Start(Handle sEvent, const char[] Name, bool DontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(sEvent, "userid"));
	RespawnNumber[client] = 0;
}

public void OnConfigsExecuted() {
	
}