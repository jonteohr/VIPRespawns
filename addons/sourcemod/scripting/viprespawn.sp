/*
* ###########################################
* #											#
* #				 VIPRespawns				#
* #				   v1.5.7 (005)				#
* #											#
* ###########################################
* 
* TEAM VARIABLES
* CS_TEAM_NONE
* CS_TEAM_SPECTATOR
* CS_TEAM_T
* CS_TEAM_CT
*/

#include <sourcemod>
#include <colors>
#include <cstrike>
#include <adminmenu>

#define CHOICE1 "#choice1"
#define CHOICE2 "#choice2"

#define VERSION "1.5.7 (005)"
#define prefix "[{green}VIPRespawns{default}]"

#undef REQUIRE_PLUGIN

int Number;
int RespawnNumber[MAXPLAYERS +1];
int RespawnLeft[MAXPLAYERS +1];
int AlivePlayers;

ConVar cvNumber;
ConVar cvMenu;
ConVar cvVIPVersion;
ConVar cvAlive;
ConVar cvAliveSide;

new Handle:hAdminMenu = INVALID_HANDLE;
TopMenuObject obj_dmcommands;

public Plugin myinfo = {
	name = "VIPRespawns",
	author = "Hypr & BaroNN",
	description = "Gives VIP players some respawns per map.",
	version = VERSION,
	url = "https://github.com/condolent/viprespawns"
};

public void OnPluginStart() {
	
	cvNumber = CreateConVar("sm_respawn_amount", "3", "Amount of times a user is allowed to respawn per map");
	cvMenu = CreateConVar("sm_enable_vip_menu", "1", "Enable the VIP-menu called with !vip?\n(0 = Disable, 1 = Enable)", _, true, 0.0, true, 1.0);
	cvVIPVersion = CreateConVar("sm_viprespawn_version", VERSION, "The version of VIPRespawns you're running.", FCVAR_DONTRECORD);
	cvAlive = CreateConVar("sm_minimum_players_alive", "3", "How many players needs to be alive in order to respawn\nSet 0 to allow all the time.");
	cvAliveSide = CreateConVar("sm_minimum_players_alive_side", "0", "Counter-Strike only!\nShould the sm_minimum_players_alive only count players playing on a specific side?\n0 = Track all teams. 1 = Track terrorists. 2 = Track counter-terrorists.");
	
	Number = cvNumber.IntValue;
	
	AutoExecConfig(true, "viprespawns");
	RegAdminCmd("sm_vipspawn", sm_vipspawn, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_spawnsleft", sm_spawnsleft, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_checkrespawn", sm_checkrespawn, ADMFLAG_KICK);
	
	new Handle:topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null)) {
		OnAdminMenuReady(topmenu);
	}
	
	// Menu
	if(cvMenu.IntValue == 1) {
		RegAdminCmd("sm_vip", sm_vip, ADMFLAG_RESERVATION);
	}
}


public void OnMapStart() {
	
	for(new i = 1; i <= MaxClients;  i++) {
		
		RespawnNumber[i] = 0;
		RespawnLeft[i] = Number;
	}
	
}

// !vip
public Action sm_vip(int client, int args) {
	
	char buff[128];
	Format(buff, sizeof(buff), "Respawns left: %d", RespawnLeft[client]);
	
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
			// Menu opened
		}
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "VIP Menu", client);
			
			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, CHOICE1)) {
				
				FakeClientCommand(client, "sm_vipspawn");
				
			} 
			if(StrEqual(info, CHOICE2)) {
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
	
	CPrintToChat(client, "%p You have %d respawns left!", prefix, RespawnLeft[client]);
	
	return Plugin_Handled;
}

public Action sm_vipspawn(int client, int args) {
	
	if(cvAliveSide.IntValue == 0) {
		for(new i=1; i<=MaxClients; i++) {
			if(IsClientInGame(i) && IsPlayerAlive(i)) {
				AlivePlayers++;
			}
		}
	} else if(cvAliveSide.IntValue == 1) {
		for(new i=1; i<=MaxClients; i++) {
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T) {
				AlivePlayers++;
			}
		}
	} else if(cvAliveSide.IntValue == 2) {
		for(new i=1; i<=MaxClients; i++) {
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT) {
				AlivePlayers++;
			}
		}
	}
	
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	if(GetClientTeam(client) != CS_TEAM_SPECTATOR) {
		if(cvAlive.IntValue != 0 && AlivePlayers >= cvAlive.IntValue) {
			// Make sure client is alive
			if (!IsPlayerAlive(client)) {
				
				// Check how many times client has respawned
				if(RespawnNumber[client] < Number) {
					
					CS_RespawnPlayer(client);
					RespawnNumber[client] += 1;
					RespawnLeft[client] -= 1;
					CPrintToChatAll("%p %s used a Respawn!", prefix, name);
					
				} else {
					CPrintToChat(client, "%p You have used all your respawns!", prefix);
				}
				
			} else {
				CPrintToChat(client, "%p You cannot respawn when alive!", prefix);
			}
		} else if(cvAlive.IntValue != 0 && AlivePlayers < cvAlive.IntValue) {
			CPrintToChat(client, "%p Not enough players alive. 3 players needs to be alive!", prefix);
		} 
		if(cvAlive.IntValue == 0) {
			// Make sure client is alive
			if (!IsPlayerAlive(client)) {
				
				// Check how many times client has respawned
				if(RespawnNumber[client] < Number) {
					
					CS_RespawnPlayer(client);
					RespawnNumber[client] += 1;
					RespawnLeft[client] -= 1;
					CPrintToChatAll("%p %s used a Respawn!", prefix, name);
					
				} else {
					CPrintToChat(client, "%p You have used all your respawns!", prefix);
				}
				
			} else {
				CPrintToChat(client, "%p You cannot respawn when alive!", prefix);
			}
		}
	} else {
		CPrintToChat(client, "%p You cannot respawn as spectator..", prefix);
	}
	
	return Plugin_Handled;
}

// !checkrespawn
public Action sm_checkrespawn(int client, int args) {
	
	CPrintToChat(client, "%p This command does not fulfill a purpose as of yet..", prefix);
	
	/*
	* TODO: Make command argument[0] to convert to userID and lookup available respawns.
	*/
	
}

// Useless method required for AutoExecConfig
public void OnConfigsExecuted() {
	
}

// ######## MENU STUFF ########
public OnLibraryRemoved(const String:name[]) {
	if(StrEqual(name, "adminmenu")) {
		hAdminMenu = INVALID_HANDLE;
	}
}

public void OnAdminMenuReady(Handle:topmenu) {
	
	if(obj_dmcommands == INVALID_TOPMENUOBJECT) {
		OnAdminMenuCreated(topmenu);
	}
	
	if(topmenu == hAdminMenu) {
		return;
	}
	
	hAdminMenu = Handle:topmenu;
	
	// TODO: Add stuff to the menu
	
}

public void OnAdminMenuCreated(Handle:topmenu) {
	
	if(topmenu == hAdminMenu && obj_dmcommands != INVALID_TOPMENUOBJECT) {
		return;
	}
	
	obj_dmcommands = AddToTopMenu(topmenu, "VIPRespawns", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT);
	
}

public void CategoryHandler(Handle:topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	
	if(action == TopMenuAction_DisplayTitle) {
		Format(buffer, maxlength, "VIPRespawns:");
	} else if(action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "VIPRespawns");
	}
	
}

public void AttachAdminMenu() {
	
	TopMenuObject player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
	
	if(player_commands == INVALID_TOPMENUOBJECT) {
		return; // *ERROR*
	}
	
	AddToTopMenu(hAdminMenu, "sm_vipspawn", TopMenuObject_Item, AdminMenu_TestEntry, player_commands, "sm_vipspawn", ADMFLAG_SLAY);
	
}

public void AdminMenu_TestEntry(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength) {
	
	if(action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Test!!");
	} else if(action == TopMenuAction_SelectOption) {
		CPrintToChat(client, "%p You pressed the admin-menu button!", prefix);
	}
	
}
