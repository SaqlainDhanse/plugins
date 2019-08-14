#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
new vault_value[128]
#define COOLDOWN_TIME_VALUE 300
#define MAX_PLAYERS 32
#define MAX_NAME_LENGTH 32
#define COLORS 6
#define DRINKIN_TIME 10
#define SMOKIN_TIME 10 
#define LSDHIGH_TIME 10 
#define COKEHIGH_TIME 10
#define MARYJANE_TIME 10
#define MaxClients 32
new RTDoption;
new Array:g_mapName;
new g_mapNums
new g_menuPosition[MAX_PLAYERS + 1]
new pm_sound[32]
new g_MAPvoteMAPCount[5]
new cooldown_time[32]
new g_voteSelected[MAX_PLAYERS + 1][4]
new g_voteSelectedNum[MAX_PLAYERS + 1]
new g_MAPcoloredMenus
new g_choosed

new ban_reason[64]

new g_Answer[128]
new g_Answer_display[128]
new g_optionName[4][64]
new g_voteCount[4]
new g_validMaps
new g_yesNoVote
new g_coloredMenus
new g_voteCaller
new g_Execute[256]
new g_Display[256]
new g_execLen

new bool:g_execResult
new Float:g_voteRatio
new bool:DrugFlag[32] 
new smoke
new moves[4][] = {"+moveleft","+moveright","+back","+forward"}
new move[4][] = {"+left","+right","+back","+forward"}
new dcounter[32]
new scounter[32]
new lcounter[32]
new ccounter[32]
new mcounter[32]
new sccounter[32]
new moved[32]
new is_drunk[32]
new is_smoke[32]
new is_lsd[32]
new is_coke[32]
new is_maryjane[32]
new is_crack[32]
new all_drunk
new all_smoke
new all_lsd
new all_coke
new all_crack
new all_maryjane
new wbottle
new bool:drugs_on = true
new bool:dod_running
new gmsgShake 
new colors[COLORS][3] = {{255,0,0},{0,255,0},{0,0,255},{255,255,0},{255,0,255},{0,255,255}}
new gmsgFade
new victim 
new gmsgSetFOV 

#define Keyschooseplayer (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
#define Keysyousure (1<<0)|(1<<1) // Keys: 12
#define Keysallvote (1<<0)|(1<<1)|(1<<3)|(1<<5) // Keys: 1246

#define VaultKey "VoteKick_%s"
#define VaultKeyTime "VoteKickTime_%s"







#define MENU_KEYS (1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<4 | 1<<5 | 1<<6 | 1<<7 | 1<<8 | 1<<9)
#define MENU_SLOTS 8







#define VIP_FLAG 	ADMIN_RESERVATION //flag 'b' required.
#define SVIP_FLAG	ADMIN_CHAT //flag 'i' required.
#define PLUGIN "JB VIP Menu"
#define VERSION "1.0"
#define AUTHOR "Saqlain"
new toggle_pcvar
new toggleCache

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_clcmd("amx_mapmenu", "cmdMapsMenu", ADMIN_MAP, "- displays changelevel menu")
	register_clcmd("amx_openvotemapmenu", "cmdVoteMapMenu", VIP_FLAG, "- displays votemap menu")

	register_menucmd(register_menuid("Changelevel Menu"), 1023, "actionMapsMenu")
	register_menucmd(register_menuid("Which map do you want?"), 527, "voteMAPCount")
	register_menucmd(register_menuid("Change map to"), 527, "voteMAPCount")
	register_menucmd(register_menuid("Votemap Menu"), 1023, "actionVoteMapMenu")
	register_menucmd(register_menuid("The winner: "), 3, "actionMAPResult")

	g_mapName=ArrayCreate(32);
	

	for(new i=1;i<32;i++)
		cooldown_time[i]=0;

	new maps_ini_file[64];
	get_configsdir(maps_ini_file, charsmax(maps_ini_file));
	format(maps_ini_file, charsmax(maps_ini_file), "%s/maps.ini", maps_ini_file);

	if (!file_exists(maps_ini_file))
		get_cvar_string("mapcyclefile", maps_ini_file, charsmax(maps_ini_file));
		
	if (!file_exists(maps_ini_file))
		format(maps_ini_file, charsmax(maps_ini_file), "mapcycle.txt")
	
	load_settings(maps_ini_file)

	g_MAPcoloredMenus = colored_menus()

	register_dictionary("adminvote.txt")
	register_dictionary("common.txt")
	register_dictionary("mapsmenu.txt")
	register_menucmd(register_menuid("Change map to "), MENU_KEY_1|MENU_KEY_2, "voteCount")
	register_menucmd(register_menuid("Choose map: "), MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4, "voteCount")
	register_menucmd(register_menuid("Kick "), MENU_KEY_1|MENU_KEY_2, "voteCount")
	register_menucmd(register_menuid("Ban "), MENU_KEY_1|MENU_KEY_2, "voteCount")
	register_menucmd(register_menuid("Vote: "), MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4, "voteCount")
	register_menucmd(register_menuid("The result: "), MENU_KEY_1|MENU_KEY_2, "actionResult")
	register_clcmd("amx_votekick_player_name", "cmdVoteKickBan", VIP_FLAG, "<name or #userid>")
	register_clcmd("amx_voteban_player_name", "cmdVoteKickBan", SVIP_FLAG, "<name or #userid>")
	RegisterHam(Ham_Killed, "player", "client_pre_death", 0)
	
	g_coloredMenus = colored_menus()

	ban_reason = "now";
		
	toggle_pcvar = register_cvar("jb_vipmenu", "0")
	register_clcmd("say /vipmenu", "openvm", VIP_FLAG, "-Opens the VIP Menu")
	register_clcmd("say /vm", "openvm", VIP_FLAG, "-Opens the VIP Menu")
	register_clcmd("say", "checkvm", 0, "Chat")
	gmsgFade = get_user_msgid("ScreenFade")
	gmsgShake = get_user_msgid("ScreenShake") 
  	register_event("DeathMsg","death","a") 
  	toggleCache = get_pcvar_num(toggle_pcvar)
	createVIPMenu()
	
	register_srvcmd("botsay","handle_botsayplugin")
	register_cvar("amx_luds_drunkmode","v1.1",FCVAR_SERVER )

	gmsgSetFOV = get_user_msgid("SetFOV") 
	register_event("SetFOV", "event_SetFOV", "be", "1<91") 
	ejl_vault("READ","DRINKIN","")
	if(equali(vault_value,"off"))
		drugs_on = false
	else
		drugs_on = true



	
	return PLUGIN_CONTINUE
}
new g_mainMenu
new g_drugMenu
new g_reasonMenu
new g_reasonKickMenu
createVIPMenu()
{
	g_mainMenu = menu_create("VIP Menu", "menuHandler")
	
	menu_additem(g_mainMenu, "Drugs - 10 seconds.", "1", 0)
	menu_additem(g_mainMenu, "Slap a player in game once", "2", 0)
	menu_additem(g_mainMenu, "Votemap", "3", 0)
	menu_additem(g_mainMenu, "Votekick", "4", 0)
	menu_additem(g_mainMenu, "Voteban (SVIP/ADMIN)", "5", SVIP_FLAG)
	menu_additem(g_mainMenu, "Roll the Dice", "6", 0)
	menu_additem(g_mainMenu, "Paint (SVIP/ADMIN)", "7", SVIP_FLAG)
	//menu_additem(g_mainMenu, "Speed", "8", 0)
	menu_additem(g_mainMenu, "Full HP", "8", 0)
	menu_additem(g_mainMenu, "Gravity", "9", 0)
	
	menu_setprop(g_mainMenu, MPROP_EXIT, MEXIT_ALL)

	g_drugMenu = menu_create("Drugs Menu", "drugHandler")
	
	menu_additem(g_drugMenu, "Drink", "1", 0)
	menu_additem(g_drugMenu, "Smoke", "2", 0)
	menu_additem(g_drugMenu, "Cocaine", "3", 0)
	menu_additem(g_drugMenu, "Smoke Crack", "4", 0)
	menu_additem(g_drugMenu, "Back", "5", 0)
	
	menu_setprop(g_drugMenu, MPROP_EXIT, MEXIT_ALL)

	g_reasonMenu = menu_create("Select a reason for Ban", "reasonHandler")
	
	menu_additem(g_reasonMenu, "Abusing", "1", 0)
	menu_additem(g_reasonMenu, "Laming the gameplay", "2", 0)
	menu_additem(g_reasonMenu, "Cheating", "3", 0)
	menu_additem(g_reasonMenu, "Spamming in mic/chat", "4", 0)
	menu_additem(g_reasonMenu, "Swearing/Insulting", "5", 0)
	menu_additem(g_reasonMenu, "Back to VIP Menu", "6", 0)

	menu_setprop(g_reasonMenu, MPROP_EXIT, MEXIT_ALL)

	g_reasonKickMenu = menu_create("Select a reason for Kick", "reasonKickHandler")
	
	menu_additem(g_reasonKickMenu, "Abusing", "1", 0)
	menu_additem(g_reasonKickMenu, "Laming the gameplay", "2", 0)
	menu_additem(g_reasonKickMenu, "Cheating", "3", 0)
	menu_additem(g_reasonKickMenu, "Spamming in mic/chat", "4", 0)
	menu_additem(g_reasonKickMenu, "Swearing/Insulting", "5", 0)
	menu_additem(g_reasonKickMenu, "Back to VIP Menu", "6", 0)

	menu_setprop(g_reasonKickMenu, MPROP_EXIT, MEXIT_ALL)

	return PLUGIN_CONTINUE
}

public client_connect(id)
{
	cooldown_time[id]=0;
}


public actionMAPResult(id, key)
{
	remove_task(4545454)
	
	switch (key)
	{
		case 0:
		{
			new _modName[10]
			get_modname(_modName, charsmax(_modName))
			
			if (!equal(_modName, "zp"))
			{
				message_begin(MSG_ALL, SVC_INTERMISSION)
				message_end()
			}

			new tempMap[32];
			ArrayGetString(g_mapName, g_choosed, tempMap, charsmax(tempMap));
			
			set_task(2.0, "delayedChange", 0, tempMap, strlen(tempMap) + 1)
			log_amx("Vote: %L", "en", "RESULT_ACC")
			client_print(0, print_chat, "%L", LANG_PLAYER, "RESULT_ACC")
		}
		case 1: autoRefuse()
	}
	
	return PLUGIN_HANDLED
}

public checkMAPVotes(id)
{
	id -= 34567
	new num, ppl[MAX_PLAYERS], a = 0
	
	get_players(ppl, num, "c")
	if (num == 0) num = 1
	g_choosed = -1
	
	for (new i = 0; i < g_voteSelectedNum[id]; ++i)
		if (g_MAPvoteMAPCount[a] < g_MAPvoteMAPCount[i])
			a = i

	new votesNum = g_MAPvoteMAPCount[0] + g_MAPvoteMAPCount[1] + g_MAPvoteMAPCount[2] + g_MAPvoteMAPCount[3] + g_MAPvoteMAPCount[4]
	new iRatio = votesNum ? floatround(get_cvar_float("amx_votemap_ratio") * float(votesNum), floatround_ceil) : 1
	new iResult = g_MAPvoteMAPCount[a]

	if (iResult >= iRatio)
	{
		g_choosed = g_voteSelected[id][a]
		new tempMap[32];
		ArrayGetString(g_mapName, g_choosed, tempMap, charsmax(tempMap));
		client_print(0, print_chat, "%L %s", LANG_PLAYER, "VOTE_SUCCESS", tempMap);
		log_amx("Vote: %L %s", "en", "VOTE_SUCCESS", tempMap);
	}
	
	if (g_choosed != -1)
	{
		if (is_user_connected(id))
		{
			new menuBody[512]
			new tempMap[32];
			ArrayGetString(g_mapName, g_choosed, tempMap, charsmax(tempMap));
			new len = format(menuBody, charsmax(menuBody), g_MAPcoloredMenus ? "\y%L: \w%s^n^n" : "%L: %s^n^n", id, "THE_WINNER", tempMap)
			
			len += format(menuBody[len], charsmax(menuBody) - len, g_MAPcoloredMenus ? "\y%L^n\w" : "%L^n", id, "WANT_CONT")
			format(menuBody[len], charsmax(menuBody) - len, "^n1. %L^n2. %L", id, "YES", id, "NO")

			show_menu(id, 0x03, menuBody, 10, "The winner: ")
			set_task(10.0, "autoRefuse", 4545454)
		} else {
			new _modName[10]
			get_modname(_modName, charsmax(_modName))
			
			if (!equal(_modName, "zp"))
			{
				message_begin(MSG_ALL, SVC_INTERMISSION)
				message_end()
			}
			new tempMap[32];
			ArrayGetString(g_mapName, g_choosed, tempMap, charsmax(tempMap));
			set_task(2.0, "delayedChange", 0, tempMap, strlen(tempMap) + 1)
		}
	} else {
		client_print(0, print_chat, "%L", LANG_PLAYER, "VOTE_FAILED")
		log_amx("Vote: %L", "en", "VOTE_FAILED")
	}
	
	remove_task(34567 + id)
}

public voteMAPCount(id, key)
{
	if (key > 3)
	{
		client_print(0, print_chat, "%L", LANG_PLAYER, "VOT_CANC")
		remove_task(34567 + id)
		set_cvar_float("amx_last_voting", get_gametime())
		log_amx("Vote: Cancel vote session")
		
		return PLUGIN_HANDLED
	}
	
	if (get_cvar_float("amx_vote_answers"))
	{
		new name[MAX_NAME_LENGTH]
		
		get_user_name(id, name, charsmax(name))
		client_print(0, print_chat, "%L", LANG_PLAYER, "X_VOTED_FOR", name, key + 1)
	}
	
	++g_MAPvoteMAPCount[key]
	
	return PLUGIN_HANDLED
}

isMapSelected(id, pos)
{
	for (new a = 0; a < g_voteSelectedNum[id]; ++a)
		if (g_voteSelected[id][a] == pos)
			return 1
	return 0
}

displayVoteMapsMenu(id, pos)
{
	if (pos < 0)
		return

	new menuBody[512], b = 0, start = pos * 7

	if (start >= g_mapNums)
		start = pos = g_menuPosition[id] = 0

	new len = format(menuBody, charsmax(menuBody), g_MAPcoloredMenus ? "\y%L\R%d/%d^n\w^n" : "%L %d/%d^n^n", id, "VOTEMAP_MENU", pos + 1, (g_mapNums / 7 + ((g_mapNums % 7) ? 1 : 0)))
	new end = start + 7, keys = MENU_KEY_0

	if (end > g_mapNums)
		end = g_mapNums

	new tempMap[32];
	for (new a = start; a < end; ++a)
	{
		ArrayGetString(g_mapName, a, tempMap, charsmax(tempMap));
		if (g_voteSelectedNum[id] == 4 || isMapSelected(id, pos * 7 + b))
		{
			++b
			if (g_MAPcoloredMenus)
				len += format(menuBody[len], charsmax(menuBody) - len, "\d%d. %s^n\w", b, tempMap)
			else
				len += format(menuBody[len], charsmax(menuBody) - len, "#. %s^n", tempMap)
		} else {
			keys |= (1<<b)
			len += format(menuBody[len], charsmax(menuBody) - len, "%d. %s^n", ++b, tempMap)
		}
	}

	if (g_voteSelectedNum[id])
	{
		keys |= MENU_KEY_8
		len += format(menuBody[len], charsmax(menuBody) - len, "^n8. %L^n", id, "START_VOT")
	}
	else
		len += format(menuBody[len], charsmax(menuBody) - len, g_MAPcoloredMenus ? "^n\d8. %L^n\w" : "^n#. %L^n", id, "START_VOT")

	if (end != g_mapNums)
	{
		len += format(menuBody[len], charsmax(menuBody) - len, "^n9. %L...^n0. %L^n", id, "MORE", id, pos ? "BACK" : "EXIT")
		keys |= MENU_KEY_9
	}
	else
		len += format(menuBody[len], charsmax(menuBody) - len, "^n0. %L^n", id, pos ? "BACK" : "EXIT")

	if (g_voteSelectedNum[id])
		len += format(menuBody[len], charsmax(menuBody) - len, g_MAPcoloredMenus ? "^n\y%L:^n\w" : "^n%L:^n", id, "SEL_MAPS")
	else
		len += format(menuBody[len], charsmax(menuBody) - len, "^n^n")

	for (new c = 0; c < 4; c++)
	{
		if (c < g_voteSelectedNum[id])
		{
			ArrayGetString(g_mapName, g_voteSelected[id][c], tempMap, charsmax(tempMap));
			len += format(menuBody[len], charsmax(menuBody) - len, "%s^n", tempMap)
		}
		else
			len += format(menuBody[len], charsmax(menuBody) - len, "^n")
	}

	new menuName[64]
	format(menuName, charsmax(menuName), "%L", "en", "VOTEMAP_MENU")

	show_menu(id, keys, menuBody, -1, menuName)
}

public cmdVoteMapMenu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	if (get_cvar_float("amx_last_voting") > get_gametime())
	{
		client_print(id, print_chat, "%L", id, "ALREADY_VOT")
		return PLUGIN_HANDLED
	}

	g_voteSelectedNum[id] = 0

	if (g_mapNums)
	{
		displayVoteMapsMenu(id, g_menuPosition[id] = 0)
	} else {
		console_print(id, "%L", id, "NO_MAPS_MENU")
		client_print(id, print_chat, "%L", id, "NO_MAPS_MENU")
	}

	return PLUGIN_HANDLED
}

public cmdMapsMenu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	if (g_mapNums)
	{
		displayMapsMenu(id, g_menuPosition[id] = 0)
	} else {
		console_print(id, "%L", id, "NO_MAPS_MENU")
		client_print(id, print_chat, "%L", id, "NO_MAPS_MENU")
	}

	return PLUGIN_HANDLED
}

public delayedChange(mapname[])
{
	engine_changelevel(mapname)

}

public actionVoteMapMenu(id, key)
{
	new tempMap[32];
	switch (key)
	{
		case 7:
		{
			new Float:voting = get_cvar_float("amx_last_voting")
		
			if (voting > get_gametime())
			{
				client_print(id, print_chat, "%L", id, "ALREADY_VOT")
				return PLUGIN_HANDLED
			}

			if (voting && voting + get_cvar_float("amx_vote_delay") > get_gametime())
			{
				client_print(id, print_chat, "%L", id, "VOT_NOW_ALLOW")
				return PLUGIN_HANDLED
			}

			g_MAPvoteMAPCount = {0, 0, 0, 0, 0}
			
			new Float:vote_time = get_cvar_float("amx_vote_time") + 2.0
			set_cvar_float("amx_last_voting", get_gametime() + vote_time)
			new iVoteTime = floatround(vote_time)

			set_task(vote_time, "checkMAPVotes", 34567 + id)

			new menuBody[512]
			new players[MAX_PLAYERS]
			new pnum, keys, len

			get_players(players, pnum)

			if (g_voteSelectedNum[id] > 1)
			{
				len = format(menuBody, charsmax(menuBody), g_MAPcoloredMenus ? "\y%L^n\w^n" : "%L^n^n", id, "WHICH_MAP")
				
				for (new c = 0; c < g_voteSelectedNum[id]; ++c)
				{
					ArrayGetString(g_mapName, g_voteSelected[id][c], tempMap, charsmax(tempMap));
					len += format(menuBody[len], charsmax(menuBody) - len, "%d. %s^n", c + 1, tempMap)
					keys |= (1<<c)
				}
				
				keys |= (1<<8)
				len += format(menuBody[len], charsmax(menuBody) - len, "^n9. %L^n", id, "NONE")
			} else {
				ArrayGetString(g_mapName, g_voteSelected[id][0], tempMap, charsmax(tempMap));
				len = format(menuBody, charsmax(menuBody), g_MAPcoloredMenus ? "\y%L^n%s?^n\w^n1. %L^n2. %L^n" : "%L^n%s?^n^n1. %L^n2. %L^n", id, "CHANGE_MAP_TO", tempMap, id, "YES", id, "NO")
				keys = MENU_KEY_1|MENU_KEY_2
			}

			new menuName[64]
			format(menuName, charsmax(menuName), "%L", "en", "WHICH_MAP")

			for (new b = 0; b < pnum; ++b)
				if (players[b] != id)
					show_menu(players[b], keys, menuBody, iVoteTime, menuName)

			format(menuBody[len], charsmax(menuBody), "^n0. %L", id, "CANC_VOTE")
			keys |= MENU_KEY_0
			show_menu(id, keys, menuBody, iVoteTime, menuName)

			new authid[32], name[MAX_NAME_LENGTH]
			
			get_user_authid(id, authid, charsmax(authid))
			get_user_name(id, name, charsmax(name))

			show_activity_key("ADMIN_V_MAP_1", "ADMIN_V_MAP_2", name);

			new tempMapA[32];
			new tempMapB[32];
			new tempMapC[32];
			new tempMapD[32];
			if (g_voteSelectedNum[id] > 0)
			{
				ArrayGetString(g_mapName, g_voteSelected[id][0], tempMapA, charsmax(tempMapA));
			}
			else
			{
				copy(tempMapA, charsmax(tempMapA), "");
			}
			if (g_voteSelectedNum[id] > 1)
			{
				ArrayGetString(g_mapName, g_voteSelected[id][1], tempMapB, charsmax(tempMapB));
			}
			else
			{
				copy(tempMapB, charsmax(tempMapB), "");
			}
			if (g_voteSelectedNum[id] > 2)
			{
				ArrayGetString(g_mapName, g_voteSelected[id][2], tempMapC, charsmax(tempMapC));
			}
			else
			{
				copy(tempMapC, charsmax(tempMapC), "");
			}
			if (g_voteSelectedNum[id] > 3)
			{
				ArrayGetString(g_mapName, g_voteSelected[id][3], tempMapD, charsmax(tempMapD));
			}
			else
			{
				copy(tempMapD, charsmax(tempMapD), "");
			}
			
			log_amx("Vote: ^"%s<%d><%s><>^" vote maps (map#1 ^"%s^") (map#2 ^"%s^") (map#3 ^"%s^") (map#4 ^"%s^")", 
					name, get_user_userid(id), authid, 
					tempMapA, tempMapB, tempMapC, tempMapD)
		}
		case 8: displayVoteMapsMenu(id, ++g_menuPosition[id])
		case 9: displayVoteMapsMenu(id, --g_menuPosition[id])
		default:
		{
			g_voteSelected[id][g_voteSelectedNum[id]++] = g_menuPosition[id] * 7 + key
			displayVoteMapsMenu(id, g_menuPosition[id])
		}
	}

	return PLUGIN_HANDLED
}

public actionMapsMenu(id, key)
{
	switch (key)
	{
		case 8: displayMapsMenu(id, ++g_menuPosition[id])
		case 9: displayMapsMenu(id, --g_menuPosition[id])
		default:
		{
			new a = g_menuPosition[id] * 8 + key
			new _modName[10]

			get_modname(_modName, charsmax(_modName))
			if (!equal(_modName, "zp"))
			{
				message_begin(MSG_ALL, SVC_INTERMISSION)
				message_end()
			}
			
			new authid[32], name[MAX_NAME_LENGTH]
			
			get_user_authid(id, authid, charsmax(authid))
			get_user_name(id, name, charsmax(name))

			new tempMap[32];
			ArrayGetString(g_mapName, a, tempMap, charsmax(tempMap));
			
			show_activity_key("ADMIN_CHANGEL_1", "ADMIN_CHANGEL_2", name, tempMap);
			//start_cooldown(id);
			log_amx("Cmd: ^"%s<%d><%s><>^" changelevel ^"%s^"", name, get_user_userid(id), authid, tempMap)
			set_task(2.0, "delayedChange", 0, tempMap, strlen(tempMap) + 1)
			/* displayMapsMenu(id, g_menuPosition[id]) */
		}
	}
	
	return PLUGIN_HANDLED
}

displayMapsMenu(id, pos)
{
	if (pos < 0)
		return

	new menuBody[512]
	new tempMap[32]
	new start = pos * 8
	new b = 0

	if (start >= g_mapNums)
		start = pos = g_menuPosition[id] = 0

	new len = format(menuBody, charsmax(menuBody), g_MAPcoloredMenus ? "\y%L\R%d/%d^n\w^n" : "%L %d/%d^n^n", id, "CHANGLE_MENU", pos + 1, (g_mapNums / 8 + ((g_mapNums % 8) ? 1 : 0)))
	new end = start + 8
	new keys = MENU_KEY_0

	if (end > g_mapNums)
		end = g_mapNums

	for (new a = start; a < end; ++a)
	{
		keys |= (1<<b)
		ArrayGetString(g_mapName, a, tempMap, charsmax(tempMap));
		len += format(menuBody[len], charsmax(menuBody) - len, "%d. %s^n", ++b, tempMap)
	}

	if (end != g_mapNums)
	{
		format(menuBody[len], charsmax(menuBody) - len, "^n9. %L...^n0. %L", id, "MORE", id, pos ? "BACK" : "EXIT")
		keys |= MENU_KEY_9
	}
	else
		format(menuBody[len], charsmax(menuBody) - len, "^n0. %L", id, pos ? "BACK" : "EXIT")

	new menuName[64]
	format(menuName, 63, "%L", "en", "CHANGLE_MENU")

	show_menu(id, keys, menuBody, -1, menuName)
}
stock bool:ValidMap(mapname[])
{
	if ( is_map_valid(mapname) )
	{
		return true;
	}
	// If the is_map_valid check failed, check the end of the string
	new len = strlen(mapname) - 4;
	
	// The mapname was too short to possibly house the .bsp extension
	if (len < 0)
	{
		return false;
	}
	if ( equali(mapname[len], ".bsp") )
	{
		// If the ending was .bsp, then cut it off.
		// the string is byref'ed, so this copies back to the loaded text.
		mapname[len] = '^0';
		
		// recheck
		if ( is_map_valid(mapname) )
		{
			return true;
		}
	}
	
	return false;
}

load_settings(filename[])
{
	new fp = fopen(filename, "r");
	
	if (!fp)
	{
		return 0;
	}
		

	new text[256];
	new tempMap[32];
	
	while (!feof(fp))
	{
		fgets(fp, text, charsmax(text));
		
		if (text[0] == ';')
		{
			continue;
		}
		if (parse(text, tempMap, charsmax(tempMap)) < 1)
		{
			continue;
		}
		if (!ValidMap(tempMap))
		{
			continue;
		}
		
		ArrayPushString(g_mapName, tempMap);
		g_mapNums++;
	}

	fclose(fp);

	return 1;
}

public plugin_end()
{
	ArrayDestroy(g_mapName)
}





public checkvm(id)
{
	if(toggleCache == -1)
		return PLUGIN_CONTINUE

	new args[300];
	read_args(args, charsmax(args))
	if(equal(args,"vipmenu") || equal(args,"vm") || equal(args,"VIPMENU") || equal(args,"VM"))
		client_cmd(id,"say /vm");
	return PLUGIN_CONTINUE
}


public openvm(id, level, cid)	
{

	if(toggleCache == -1)
		return PLUGIN_CONTINUE

	if( !cmd_access( id, level, cid, 1))
	{
		client_print(id,print_chat,"You are not a VIP. Visit reg.ugc.lt for more details.");
		return PLUGIN_HANDLED
	}
	if(cooldown_time[id]<=0)
		menu_display(id, g_mainMenu, 0)
	else
	{
		if(cooldown_time[id]==1000)
			client_print(id,print_chat,"[VIP] You can't use VIP Menu at this moment.");
		else
			client_print(id,print_chat,"[VIP] You can use VIP Menu again in %d second(s).",cooldown_time[id]);

	}
		
	return PLUGIN_HANDLED
}

public votekickName(id)
{
	client_cmd(id, "messagemode amx_votekick_player_name");
	start_cooldown(id);		
}

public votebanName(id)
{
	client_cmd(id, "messagemode amx_voteban_player_name");
	start_cooldown(id);		
}

public votemapName(id)
{
	client_cmd(id, "amx_openvotemapmenu");
	start_cooldown(id);
}

public menuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		
		return PLUGIN_HANDLED
	}
	
	new choice, acs, cb
	new data[3], name[32]
	menu_item_getinfo(menu, item, acs, data, charsmax(data), name, charsmax(name), cb)
	
	choice = str_to_num(data)
	
	switch(choice)
	{
		case 1:	menu_display(id, g_drugMenu, 0);
		case 2:	slapMenu(id);
		case 3:	votemapName(id);
		case 4:	menu_display(id, g_reasonKickMenu, 0);
		case 5:	menu_display(id, g_reasonMenu, 0);
		case 6:	RTDManager(id);
		case 7:	PaintManager(id)
		//case 8:	set_speed(id);
		case 8:	set_full_health(id);
		case 9: set_gravity(id);
		
	}
	
	
	return PLUGIN_HANDLED
}

public PaintManager(id)
{
	client_cmd(id,"vip_paint_toggle");
	cooldown_time[id]=(COOLDOWN_TIME_VALUE + 21);
	cooldown(id);
}
public drugHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		
		return PLUGIN_HANDLED
	}
	
	new choice, acs, cb
	new data[3], name[32]
	menu_item_getinfo(menu, item, acs, data, charsmax(data), name, charsmax(name), cb)
	
	choice = str_to_num(data)
	
	switch(choice)
	{
		case 1:	make_me_drunk(id);
		case 2:	make_me_smoke(id);
		case 3:	make_me_snortcoke(id);
		case 4:	make_me_smokecrack(id);
		case 5:	menu_display(id, g_mainMenu, 0);
		
	}
	
	
	return PLUGIN_HANDLED
}

public reasonHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		
		return PLUGIN_HANDLED
	}
	
	new choice, acs, cb
	new data[3], name[32]
	menu_item_getinfo(menu, item, acs, data, charsmax(data), name, charsmax(name), cb)
	
	choice = str_to_num(data)
	
	switch(choice)
	{
		case 1:	abusing(id);
		case 2:	laming(id);
		case 3:	cheating(id);
		case 4:	spamming(id);
		case 5:	insulting(id);
		case 6:	menu_display(id, g_mainMenu, 0);
	}
	
	
	return PLUGIN_HANDLED
}

public reasonKickHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		
		return PLUGIN_HANDLED
	}
	
	new choice, acs, cb
	new data[3], name[32]
	menu_item_getinfo(menu, item, acs, data, charsmax(data), name, charsmax(name), cb)
	
	choice = str_to_num(data)
	
	switch(choice)
	{
		case 1:	abusingK(id);
		case 2:	lamingK(id);
		case 3:	cheatingK(id);
		case 4:	spammingK(id);
		case 5:	insultingK(id);
		case 6:	menu_display(id, g_mainMenu, 0);
	}
	
	
	return PLUGIN_HANDLED
}

public abusing(id)
{
	ban_reason = "Abusing";
	votebanName(id);
}

public laming(id)
{
	ban_reason = "Laming the gameplay";
	votebanName(id);
}

public cheating(id)
{
	ban_reason = "Cheating";
	votebanName(id);
}

public spamming(id)
{
	ban_reason = "Spamming in mic/chat";
	votebanName(id);
}

public insulting(id)
{
	ban_reason = "Swearing/Insulting";
	votebanName(id);
}

public abusingK(id)
{
	ban_reason = "Abusing";
	votekickName(id);
}

public lamingK(id)
{
	ban_reason = "Laming the gameplay";
	votekickName(id);
}

public cheatingK(id)
{
	ban_reason = "Cheating";
	votekickName(id);
}

public spammingK(id)
{
	ban_reason = "Spamming in mic/chat";
	votekickName(id);
}

public insultingK(id)
{
	ban_reason = "Swearing/Insulting";
	votekickName(id);
}

public RTDManager(id)
{
	RTDoption = random_num(1,6);
	switch(RTDoption)
	{
		case 1: set_full_health(id);
		//case 2:	set_speed(id);
		case 2:	make_me_drunk(id);
		case 3:	make_me_smoke(id);
		case 4:	make_me_snortcoke(id);
		case 5:	make_me_smokecrack(id);
		case 6: give_deagle(id);
	}
}

public give_deagle(id)
{
	give_item(id, "weapon_deagle");
	client_print(id, print_chat,"[VIP] A deagle with 7 bullets has been provided to you. Use it wisely.");
	start_cooldown(id);

}
public plugin_precache(){
	new sound_pcvar = register_cvar("pm_sound", "buttons/bell1.wav")
	get_pcvar_string(sound_pcvar, pm_sound, charsmax(pm_sound) )
	
	if(pm_sound[0]) 
		precache_sound(pm_sound)
	new mod_name[32]
	get_modname(mod_name,31)
	dod_running = equal(mod_name,"dod") ? true : false
	if(dod_running)
		smoke = precache_model("sprites/smoke.spr")
	else
		smoke = precache_model("sprites/steam1.spr")
	if(file_exists("models/tuckerman_pale_ale_v1.mdl")==1){
		wbottle = precache_model("models/tuckerman_pale_ale_v1.mdl")
	}
	else if(file_exists("models/winebottle.mdl")==1){
		wbottle = precache_model("models/winebottle.mdl")
	}else{
		wbottle = precache_model("models/can.mdl")		
	}
	return PLUGIN_CONTINUE 
} 

public death() { 
	victim = read_data(2) 
	if(DrugFlag[victim])	
		StopDrug(victim);
	client_cmd(victim,"default_fov 90")
	is_drunk[victim] = 0
	is_smoke[victim] = 0
	is_lsd[victim] = 0
	is_coke[victim] = 0
	is_maryjane[victim] = 0
	is_crack[victim] = 0

	return PLUGIN_CONTINUE 
}

public client_pre_death(id)
{
	if(DrugFlag[id])	
		StopDrug(id);
	client_cmd(id,"default_fov 90")
	is_drunk[id] = 0
	is_smoke[id] = 0
	is_lsd[id] = 0
	is_coke[id] = 0
	is_maryjane[id] = 0
	is_crack[id] = 0

	return PLUGIN_CONTINUE 	
}



public client_disconnected(id)
{
	if(DrugFlag[id])	
		StopDrug(id);
	client_cmd(id,"default_fov 90")
	is_drunk[id] = 0
	is_smoke[id] = 0
	is_lsd[id] = 0
	is_coke[id] = 0
	is_maryjane[id] = 0
	is_crack[id] = 0
	cooldown_time[id] = 0
	return PLUGIN_CONTINUE 
}

public Drugme(id) 
{ 
    if(is_user_alive(id)) 
    { 
        new player_name[32] 
        get_user_name(id, player_name, 31) 
        set_hudmessage(0, 225, 0, 0.05, 0.55, 0, 6.0, 6.0, 0.5, 0.15, 3) 
        //show_hudmessage(0, "%s is now drugged.", player_name) 
        //client_print(id, print_console, "You are now drugged.") 
        message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, id) 
        write_byte(170) 
        message_end() 
        DrugFlag[id]=true 
        //set_user_godmode(id,1);
    } 

    return PLUGIN_HANDLED 
} 

public StopDrug(id) 
{ 
    new player_name[32] 
    get_user_name(id, player_name, 31) 
    set_hudmessage(0, 225, 0, 0.05, 0.55, 0, 6.0, 3.0, 0.5, 0.15, 3) 
    //show_hudmessage(0, "%s is not drugged any more.", player_name) 
    //client_print(id, print_console, "You are not drugged any more.") 
    message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, id) 
    write_byte(90) 
    message_end() 
    DrugFlag[id]=false
    //set_user_godmode(id,0);
    start_cooldown(id);

    return PLUGIN_HANDLED 
} 

public event_SetFOV(id) 
{ 
    if(DrugFlag[id]) 
    { 
        message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, id) 
        write_byte(170) 
        message_end() 
    } 
}


public ejl_vault(rw[],key[],value[]){
	new data[192]
	new stxtsize = 0
	new line = 0 
	new skip = 0
	new vkey[64]
	new vvalue[128]
	new vaultwrite[192]
	if(equal(rw,"READ")){
		if(file_exists("addons/amxmodx/data/ejl_vault.ini") == 1){
			copy(vault_value,128,"")
			while((line=read_file("addons/amxmodx/data/ejl_vault.ini",line,data,192,stxtsize))!=0){
				parse(data,vkey,64,vvalue,128)
				if(equal(vkey,key)){
					copy(vault_value,128,vvalue)
				}
			}
		}else{
			write_file("addons/amxmodx/data/ejl_vault.ini", "**** Plugins use to store values -- immune to crashes and map changes ****", 0)
		}
	}
	else if(equal(rw,"WRITE")){
		if(file_exists("addons/amxmodx/data/ejl_vault.ini") == 1){		
			format(vaultwrite,192,"%s %s",key,value)
			while((line=read_file("addons/amxmodx/data/ejl_vault.ini",line,data,192,stxtsize))!=0){
				parse(data,vkey,64,vvalue,128)
				if(skip == 0){
					if( (equal(data,"")) || (equal(vkey,key)) ){
						skip = 1
						write_file("addons/amxmodx/data/ejl_vault.ini",vaultwrite,line-1)
					}
				}
				else if(equal(vkey,key)){
					write_file("addons/amxmodx/data/ejl_vault.ini","",line-1)
				}
			}
			if(skip == 0){
				write_file("addons/amxmodx/data/ejl_vault.ini",vaultwrite,-1)
			}
		}
	}
	return PLUGIN_CONTINUE
}


public sqrt(num) { 
	new div = num 
	new result = 1 
	while (div > result) { // end when div == result, or just below 
		div = (div + result) / 2 // take mean value as new divisor 
		result = num / div 
	} 
	return div 
} 

public admin_drinkin(id,level,cid){
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	new name[32],tname[32]
	get_user_name(id,name,31)
	new arg2[8],arg[32],ccmd[32],drtime
	read_argv(0,ccmd,31)
	if(equali(ccmd[14],"a",1)){
		read_argv(1,arg2,31)	
	}else{
		read_argv(1,arg,31)
		read_argv(2,arg2,7)
	}
	drtime = str_to_num(arg2) * 2
	if(drtime < 10 || drtime > 360)
		drtime = 10
	new idargs[2]
	idargs[1] = drtime
	if(equali(ccmd[14],"a",1)){
		if(all_drunk == 1){
			console_print(id,"[AMX] Sorry, everyone's already too drunk")
			return PLUGIN_HANDLED
		}
		all_drunk = 1
		dcounter[0] = 0	
		set_task(0.5,"drinkin_a",0,idargs,2,"a",drtime)
		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: Has made us all into drunkards for %d seconds",name,drtime/2)
			case 1:	client_print(0,print_chat,"ADMIN: Has made us all into drunkards for %d seconds",drtime/2)
		}		
	}else{
		new player = cmd_target(id,arg,1)
		if (!player) return PLUGIN_HANDLED
		get_user_name(player,tname,31)
		if(is_drunk[player] == 1){
			console_print(id,"[AMX] Sorry, %s is already too drunk",tname)
			user_kill(player)
			console_print(id,"[AMX] Oh god why! %s succumed to alcohol poisining!",tname)
			return PLUGIN_HANDLED
		}
		idargs[0] = player
		is_drunk[player] = 1
		dcounter[player] = 0	
		set_task(0.5,"drinkin_1",0,idargs,2,"a",drtime)

		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: made %s a drunkard for %d seconds",name,tname,drtime/2)
			case 1:	client_print(0,print_chat,"ADMIN: made %s a drunkard for %d seconds",tname,drtime/2)
		}
	}
	new authid[16]
	get_user_authid(id,authid,15)
	log_to_file("addons/amx/admin.log","^"%s<%d><%s><>^" smokin-drinkin ^"%s^"",
		name,get_user_userid(id),authid,tname)
	return PLUGIN_HANDLED
}

public admin_smokin(id,level,cid){
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	new name[32],tname[32]
	get_user_name(id,name,31)
	new arg2[8],arg[32],ccmd[32],drtime
	read_argv(0,ccmd,31)
	if(equali(ccmd[14],"a",1)){
		read_argv(1,arg2,31)	
	}else{
		read_argv(1,arg,31)
		read_argv(2,arg2,7)
	}
	drtime = str_to_num(arg2) * 2
	if(drtime < 10 || drtime > 360)
		drtime = 10
	new idargs[2]
	idargs[1] = drtime
	if(equali(ccmd[14],"a",1)){
		if(all_smoke == 1){
			console_print(id,"[AMX] Sorry, everyone's already smoking")
			return PLUGIN_HANDLED
		}
		all_smoke = 1
		scounter[0] = 0	
		set_task(0.5,"smokin_a",0,idargs,2,"a",drtime)
		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: Has made us all into nicotine addicted freaks for %d seconds",name,drtime/2)
			case 1:	client_print(0,print_chat,"ADMIN: Has made us all into nicotine addicted freaks for %d seconds",drtime/2)
		}		
	}else{
		new player = cmd_target(id,arg,1)
		if (!player) return PLUGIN_HANDLED
		get_user_name(player,tname,31)
		if(is_smoke[player] == 1){
			console_print(id,"[AMX] Sorry, %s is already smoking",tname)
			return PLUGIN_HANDLED
		}
		idargs[0] = player
		is_smoke[player] = 1
		scounter[player] = 0	
		set_task(0.5,"smokin_1",0,idargs,2,"a",drtime)

		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: made %s a nicotine addicted freak for %d seconds",name,tname,drtime/2)
			case 1:	client_print(0,print_chat,"ADMIN: made %s a nicotine addicted freak for %d seconds",tname,drtime/2)
		}
	}
	new authid[16]
	get_user_authid(id,authid,15)
	log_to_file("addons/amx/admin.log","^"%s<%d><%s><>^" smokin-drinkin ^"%s^"",
		name,get_user_userid(id),authid,tname)
	return PLUGIN_HANDLED
}

public admin_slappin(id,level,cid){
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	new name[32],tname[32]
	get_user_name(id,name,31)
	new arg2[8],arg[32],ccmd[32],drtime
	read_argv(0,ccmd,31)
	if(equali(ccmd[14],"a",1)){
		read_argv(1,arg2,31)	
	}else{
		read_argv(1,arg,31)
		read_argv(2,arg2,7)
	}
	drtime = str_to_num(arg2) / 2
	if(drtime < 10 || drtime > 360)
		drtime = 10
	new idargs[2]
	idargs[1] = drtime
	if(equali(ccmd[14],"a",1)){
		if(all_lsd == 1){
			console_print(id,"[AMX] Sorry, everyone's already high")
			return PLUGIN_HANDLED
		}
		all_lsd = 1
		lcounter[0] = 0	
		set_task(2.0,"lsd_a",0,idargs,2,"a",drtime)
		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: Has made us all into LSD trippers for %d seconds",name,drtime/2)
			case 1:	client_print(0,print_chat,"ADMIN: Has made us all into LSD trippers for %d seconds",drtime/2)
		}		
	}else{
		new player = cmd_target(id,arg,1)
		if (!player) return PLUGIN_HANDLED
		get_user_name(player,tname,31)
		if(is_lsd[player] == 1){
			console_print(id,"[AMX] Sorry, %s is already high",tname)
			return PLUGIN_HANDLED
		}
		idargs[0] = player
		is_lsd[player] = 1
		lcounter[player] = 0	
		set_task(2.0,"lsd_1",0,idargs,2,"a",drtime)

		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: made %s a LSD tripper for %d seconds",name,tname,drtime/2)
			case 1:	client_print(0,print_chat,"ADMIN: made %s a LSD tripper for %d seconds",tname,drtime/2)
		}
	}
	new authid[16]
	get_user_authid(id,authid,15)
	log_to_file("addons/amx/admin.log","^"%s<%d><%s><>^" smokin-drinkin ^"%s^"",
		name,get_user_userid(id),authid,tname)
	return PLUGIN_HANDLED
}

public admin_snortin(id,level,cid){
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	new name[32],tname[32]
	get_user_name(id,name,31)
	new arg2[8],arg[32],ccmd[32],drtime
	read_argv(0,ccmd,31)
	if(equali(ccmd[14],"a",1)){
		read_argv(1,arg2,31)	
	}else{
		read_argv(1,arg,31)
		read_argv(2,arg2,7)
	}
	drtime = str_to_num(arg2) * 2
	if(drtime < 10 || drtime > 360)
		drtime = 10
	new idargs[2]
	idargs[1] = drtime
	if(equali(ccmd[14],"a",1)){
		if(all_coke == 1){
			console_print(id,"[AMX] Sorry, everyone's already high")
			return PLUGIN_HANDLED
		}
		all_coke = 1
		ccounter[0] = 0	
		set_task(0.5,"coke_a",0,idargs,2,"a",drtime)
		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: Has made us all into coke heads for %d seconds",name,drtime/2)
			case 1:	client_print(0,print_chat,"ADMIN: Has made us all into coke heads for %d seconds",drtime/2)
		}		
	}else{
		new player = cmd_target(id,arg,1)
		if (!player) return PLUGIN_HANDLED
		get_user_name(player,tname,31)
		if(is_coke[player] == 1){
			console_print(id,"[AMX] Sorry, %s is already snorting coke",tname)
			user_kill(player)
			console_print(id,"[AMX] Oh god why! %s died because of an OD on coke!!",tname)
			return PLUGIN_HANDLED
		}
		idargs[0] = player
		is_coke[player] = 1
		ccounter[player] = 0	
		set_task(0.5,"coke_1",0,idargs,2,"a",drtime)

		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: made %s a coke heads for %d seconds",name,tname,drtime/2)
			case 1:	client_print(0,print_chat,"ADMIN: made %s a coke heads for %d seconds",tname,drtime/2)
		}
	}
	new authid[16]
	get_user_authid(id,authid,15)
	log_to_file("addons/amx/admin.log","^"%s<%d><%s><>^" smokin-drinkin ^"%s^"",
		name,get_user_userid(id),authid,tname)
	return PLUGIN_HANDLED
}

public admin_smokincrack(id,level,cid){
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	new name[32],tname[32]
	get_user_name(id,name,31)
	new arg2[8],arg[32],ccmd[32],drtime
	read_argv(0,ccmd,31)
	if(equali(ccmd[14],"a",1)){
		read_argv(1,arg2,31)	
	}else{
		read_argv(1,arg,31)
		read_argv(2,arg2,7)
	}
	drtime = str_to_num(arg2) * 2
	if(drtime < 10 || drtime > 360)
		drtime = 10
	new idargs[2]
	idargs[1] = drtime
	if(equali(ccmd[14],"a",1)){
		if(all_crack == 1){
			console_print(id,"[AMX] Sorry, everyone's already high")
			return PLUGIN_HANDLED
		}
		all_coke = 1
		sccounter[0] = 0	
		set_task(0.5,"coke_a",0,idargs,2,"a",drtime)
		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: Has made us all into crack heads for %d seconds",name,drtime/2)
			case 1:	client_print(0,print_chat,"ADMIN: Has made us all into crack heads for %d seconds",drtime/2)
		}		
	}else{
		new player = cmd_target(id,arg,1)
		if (!player) return PLUGIN_HANDLED
		get_user_name(player,tname,31)
		if(is_crack[player] == 1){
			console_print(id,"[AMX] Sorry, %s is already smokin crack",tname)
			user_kill(player)
			console_print(id,"[AMX] Oh god why! %s died because of an OD on crack!!",tname)
			return PLUGIN_HANDLED
		}
		idargs[0] = player
		is_coke[player] = 1
		sccounter[player] = 0	
		set_task(0.5,"coke_1",0,idargs,2,"a",drtime)

		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: made %s a crack heads for %d seconds",name,tname,drtime/2)
			case 1:	client_print(0,print_chat,"ADMIN: made %s a crack heads for %d seconds",tname,drtime/2)
		}
	}
	new authid[16]
	get_user_authid(id,authid,15)
	log_to_file("addons/amx/admin.log","^"%s<%d><%s><>^" smokin-drinkin ^"%s^"",
		name,get_user_userid(id),authid,tname)
	return PLUGIN_HANDLED
}


public admin_smokinweed(id,level,cid){
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	new name[32],tname[32]
	get_user_name(id,name,31)
	new arg2[8],arg[32],ccmd[32],drtime
	read_argv(0,ccmd,31)
	if(equali(ccmd[14],"a",1)){
		read_argv(1,arg2,31)	
	}else{
		read_argv(1,arg,31)
		read_argv(2,arg2,7)
	}
	drtime = str_to_num(arg2) * 2
	if(drtime < 10 || drtime > 360)
		drtime = 10
	new idargs[2]
	idargs[1] = drtime
	if(equali(ccmd[14],"a",1)){
		if(all_maryjane == 1){
			console_print(id,"[AMX] Sorry, everyone's already high")
			return PLUGIN_HANDLED
		}
		all_maryjane = 1
		mcounter[0] = 0	
		set_task(0.5,"maryjane_a",0,idargs,2,"a",drtime)
		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: Has put us all on marijuana for %d seconds",name,drtime/2)
			case 1:	client_print(0,print_chat,"ADMIN: Has put us all on marijuana for %d seconds",drtime/2)
		}		
	}else{
		new player = cmd_target(id,arg,1)
		if (!player) return PLUGIN_HANDLED
		get_user_name(player,tname,31)
		if(is_maryjane[player] == 1){
			console_print(id,"[AMX] Sorry, %s is already smoking weed",tname)
			user_kill(player)
			console_print(id,"[AMX] Oh god why! %s is now brain dead due to weed!",tname)
			set_task(0.5,"maryjane_1",0,idargs,2,"a",99999)
			return PLUGIN_HANDLED
		}
		idargs[0] = player
		is_maryjane[player] = 1
		mcounter[player] = 0	
		set_task(0.5,"maryjane_1",0,idargs,2,"a",drtime)

		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: put %s on marijuana for %d seconds",name,tname,drtime/2)
			case 1:	client_print(0,print_chat,"ADMIN: put %s on marijuana for %d seconds",tname,drtime/2)
		}
	}
	new authid[16]
	get_user_authid(id,authid,15)
	log_to_file("addons/amx/admin.log","^"%s<%d><%s><>^" smokin-drinkin ^"%s^"",
		name,get_user_userid(id),authid,tname)
	return PLUGIN_HANDLED
}

public drinkin_1(id[]){
	new cmd[16],dfov,a,b
	dcounter[id[0]] += 1
	if(is_user_alive(id[0])){
		new vec[3]
		get_user_origin(id[0],vec)
		dfov = random_num(10,120)
		format(cmd,15,"default_fov %d",dfov)
		client_cmd(id[0],cmd)
		Drugme(id[0])		
  		message_begin(MSG_ONE,gmsgShake,{0,0,0},id[0]) 
   		write_short(1<<13) // shake amount 
  		write_short(1<<12) // shake lasts this long 
  		write_short(1<<13) // shake noise frequency 
  		message_end() 
		if(moved[id[0]]){
			client_cmd(id[0],"-moveleft;-moveright;-forward;-back;-left;-right")
			moved[id[0]] = 0
		}

		b = random_num(0,9)
		if(b == 1){
			a = random_num(0,3)				
			client_cmd(id[0],moves[a])
			moved[id[0]] = 1
			new aimvec[3] 
			new velocityvec[3] 
			new length 	 
			new speed = 500 
			get_user_origin(id[0],aimvec,2) 
			velocityvec[0]=aimvec[0]-vec[0] 
			velocityvec[1]=aimvec[1]-vec[1] 
			velocityvec[2]=aimvec[2]-vec[2] 
			length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 
			velocityvec[0]=velocityvec[0]*speed/length 
			velocityvec[1]=velocityvec[1]*speed/length 
			velocityvec[2]=velocityvec[2]*speed/length 
			// TE_MODEL from HL-SDK common/const.h 
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
			write_byte(106) 
			write_coord(vec[0]) 
			write_coord(vec[1]) 
			write_coord(vec[2]+20) 
			write_coord(velocityvec[0]) 
			write_coord(velocityvec[1]) 
			write_coord(velocityvec[2]+100) 
			write_angle (0) 
			write_short (wbottle) 
			write_byte (2) 
			write_byte (255) 
			message_end() 
		}
	}
	if(dcounter[id[0]] >= id[1]){
		if(moved[id[0]]){
			client_cmd(id[0],"-moveleft;-moveright;-forward;-back;-left;-right")
		}
		if(is_drunk[id[0]] == 1){

			new tname[32]
			get_user_name(id[0],tname,31)	
			StopDrug(id[0])
			client_print(0,print_chat,"[VIP] %s has sobered up from drinking.",tname)
		}
		is_drunk[id[0]] = 0
		client_cmd(id[0],"default_fov 90")
	}
	return PLUGIN_CONTINUE
}


public drinkin_a(id[]){
	new cmd[16],dfov,a,b
	dcounter[0] += 1
	new iMaxPlayers = get_maxplayers()+1
	for (new i = 1; i <= iMaxPlayers; i++) {
		if(is_user_alive(i)){
			Drugme(i)
			new vec[3]
			get_user_origin(id[0],vec)
			dfov = random_num(10,120)
			format(cmd,15,"default_fov %d",dfov)
			client_cmd(i,cmd)
  			message_begin(MSG_ONE,gmsgShake,{0,0,0},id[0]) 
   			write_short(1<<13) // shake amount 
  			write_short(1<<12) // shake lasts this long 
  			write_short(1<<13) // shake noise frequency 
  			message_end() 
			if(moved[i]){
				client_cmd(i,"-moveleft;-moveright;-forward;-back;-right;-left")
				moved[i] = 0
			}
			b = random_num(0,9)
			if(b == 1){
				a = random_num(0,3)				
				client_cmd(i,moves[a])
				moved[i] = 1

				new aimvec[3] 
				new velocityvec[3] 
				new length 	 
				new speed = 500 
				get_user_origin(i,aimvec,2) 
				velocityvec[0]=aimvec[0]-vec[0] 
				velocityvec[1]=aimvec[1]-vec[1] 
				velocityvec[2]=aimvec[2]-vec[2] 
				length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 
				velocityvec[0]=velocityvec[0]*speed/length 
				velocityvec[1]=velocityvec[1]*speed/length 
				velocityvec[2]=velocityvec[2]*speed/length 

				// TE_MODEL from HL-SDK common/const.h 
				message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
				write_byte(106) 
				write_coord(vec[0]) 
				write_coord(vec[1]) 
				write_coord(vec[2]+20) 
				write_coord(velocityvec[0]) 
				write_coord(velocityvec[1]) 
				write_coord(velocityvec[2]+100) 
				write_angle (0) 
				write_short (wbottle) 
				write_byte (2) 
				write_byte (255) 
				message_end() 
			}
		}
	}
	if(dcounter[0] >= id[1]){
		for (new i = 1; i <= iMaxPlayers; i++) {
			if(moved[i])
				client_cmd(i,"-moveleft;-moveright;-forward;-back;-right;-left")
		}
		if(all_drunk == 1){
			client_print(0,print_chat,"[VIP] Ok, we're all sobered up now.")
		}
		all_drunk = 0	
		client_cmd(0,"default_fov 90")
	}
	return PLUGIN_CONTINUE
}

public smokin_1(id[]){
	scounter[id[0]] += 1
	if(is_user_alive(id[0])){
		new vec[3]
		get_user_origin(id[0],vec)
		new y1,x1
		Drugme(id[0])
		x1 = random_num(-40,40)
		y1 = random_num(-40,40)
		//Smoke    
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 5 ) // 5
		write_coord(vec[0]+x1) 
		write_coord(vec[1]+y1) 
		write_coord(vec[2]+30) 
		write_short( smoke ) 
		write_byte( 30 )  // 10
		write_byte( 10 )  // 10
		message_end()
	}
	if(scounter[id[0]] >= id[1]){
		if(is_smoke[id[0]] == 1){

			new tname[32]
			get_user_name(id[0],tname,31)	
			StopDrug(id[0])
			client_print(0,print_chat,"[VIP] %s has quit smoking for now.",tname)
		}
		is_smoke[id[0]] = 0
		client_cmd(id[0],"default_fov 90")
	}
	return PLUGIN_CONTINUE
}

public smokin_a(id[]){
	scounter[0] += 1
	new iMaxPlayers = get_maxplayers()+1
	for (new i = 1; i <= iMaxPlayers; i++) {
		if(is_user_alive(i)){
			new vec[3]
			Drugme(i)
			get_user_origin(id[0],vec)
			new y1,x1
			x1 = random_num(-40,40)
			y1 = random_num(-40,40)
			//Smoke    
			message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
			write_byte( 5 ) // 5
			write_coord(vec[0]+x1) 
			write_coord(vec[1]+y1) 
			write_coord(vec[2]+30) 
			write_short( smoke ) 
			write_byte( 30 )  // 10
			write_byte( 10 )  // 10
			message_end()
		}
	}
	if(scounter[0] >= id[1]){
		for (new i = 1; i <= iMaxPlayers; i++) {
			if(moved[i])
				client_cmd(i,"-moveleft;-moveright;-forward;-back;-right;-left")
		}
		if(all_smoke == 1){
			client_print(0,print_chat,"[VIP] Ok, we're all on the patches now.")
		}
		all_smoke = 0	
		client_cmd(0,"default_fov 90")
	}
	return PLUGIN_CONTINUE
}


public lsd_1(id[]){
	new cmd[16],dfov,a,b
	lcounter[id[0]] += 1
	new ran
	ran = random_num(0,5)
	if(is_user_alive(id[0])){
		new vec[3]
		Drugme(id[0])
		get_user_origin(id[0],vec)
  		message_begin(MSG_ONE,gmsgShake,{0,0,0},id[0]) 
   		write_short(1<<15) // shake amount 
  		write_short(1<<13) // shake lasts this long 
  		write_short(1<<13) // shake noise frequency 
  		message_end() 
		message_begin(MSG_ONE,gmsgFade,{0,0,0},id[0])
		write_short( 1<<2 ) // fade lasts this long duration
		write_short( 1<<2 ) // fade lasts this long hold time
		write_short( 1<<2 ) // fade type (in / out)
		write_byte( colors[ran][0] ) // fade red
		write_byte( colors[ran][1] ) // fade green
		write_byte( colors[ran][2] ) // fade blue
		write_byte( 100 ) // fade alpha
		message_end()
		dfov = random_num(10,120)
		format(cmd,15,"default_fov %d",dfov)
		client_cmd(id[0],cmd)
		if(moved[id[0]]){
			client_cmd(id[0],"-moveleft;-moveright;-forward;-back;-left;-right")
			moved[id[0]] = 0
		}
		b = random_num(0,5)
		if(b == 1){
			a = random_num(0,3)				
			client_cmd(id[0],move[a])
			moved[id[0]] = 1
			new aimvec[3] 
			new velocityvec[3] 
			new length 	 
			new speed = 500 
			get_user_origin(id[0],aimvec,2) 
			velocityvec[0]=aimvec[0]-vec[0] 
			velocityvec[1]=aimvec[1]-vec[1] 
			velocityvec[2]=aimvec[2]-vec[2] 
			length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 
			velocityvec[0]=velocityvec[0]*speed/length 
			velocityvec[1]=velocityvec[1]*speed/length 
			velocityvec[2]=velocityvec[2]*speed/length 
			// TE_MODEL from HL-SDK common/const.h 
		}
	}
	if(lcounter[id[0]] >= id[1]){
		if(is_lsd[id[0]] == 1){

			new tname[32]
			get_user_name(id[0],tname,31)	
			StopDrug(id[0])
			client_print(0,print_chat,"[VIP] %s has quit LSD for now.",tname)
			message_begin(MSG_ONE,gmsgFade,{0,0,0},id[0])
			write_short( 0 ) // fade lasts this long duration
			write_short( 0 ) // fade lasts this long hold time
			write_short( 0 ) // fade type (in / out)
			write_byte( 0 ) // fade red
			write_byte( 0 ) // fade green
			write_byte( 0 ) // fade blue
			write_byte( 0 ) // fade alpha
		}
		is_lsd[id[0]] = 0
		client_cmd(id[0],"default_fov 90")
	}
	return PLUGIN_CONTINUE
}

public lsd_a(id[]){
	new cmd[16],dfov,a,b
	scounter[0] += 1
	new iMaxPlayers = get_maxplayers()+1
	new ran
	ran = random_num(0,5)
	for (new i = 1; i <= iMaxPlayers; i++) {
		if(is_user_alive(i)){
		new vec[3]
		Drugme(i)
		get_user_origin(id[0],vec)
  		message_begin(MSG_ONE,gmsgShake,{0,0,0},id[0]) 
   		write_short(1<<15) // shake amount 
  		write_short(1<<13) // shake lasts this long 
  		write_short(1<<13) // shake noise frequency 
  		message_end() 
		message_begin(MSG_ONE,gmsgFade,{0,0,0},id[0])
		write_short( 1<<2 ) // fade lasts this long duration
		write_short( 1<<2 ) // fade lasts this long hold time
		write_short( 1<<2 ) // fade type (in / out)
		write_byte( colors[ran][0] ) // fade red
		write_byte( colors[ran][1] ) // fade green
		write_byte( colors[ran][2] ) // fade blue
		write_byte( 100 ) // fade alpha
		message_end()
		dfov = random_num(10,120)
		format(cmd,15,"default_fov %d",dfov)
		client_cmd(id[0],cmd)
		if(moved[id[0]]){
			client_cmd(id[0],"-moveleft;-moveright;-forward;-back;-left;-right")
			moved[id[0]] = 0
		}
		b = random_num(0,5)
		if(b == 1){
			a = random_num(0,3)				
			client_cmd(id[0],move[a])
			moved[id[0]] = 1
			new aimvec[3] 
			new velocityvec[3] 
			new length 	 
			new speed = 500 
			get_user_origin(id[0],aimvec,2) 
			velocityvec[0]=aimvec[0]-vec[0] 
			velocityvec[1]=aimvec[1]-vec[1] 
			velocityvec[2]=aimvec[2]-vec[2] 
			length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 
			velocityvec[0]=velocityvec[0]*speed/length 
			velocityvec[1]=velocityvec[1]*speed/length 
			velocityvec[2]=velocityvec[2]*speed/length 
			// TE_MODEL from HL-SDK common/const.h 
			}
		}
	}
	if(lcounter[0] >= id[1]){
		for (new i = 1; i <= iMaxPlayers; i++) {
			if(moved[i])
				client_cmd(i,"-moveleft;-moveright;-forward;-back;-right;-left")
		}
		if(all_lsd == 1){
			client_print(0,print_chat,"[VIP] Ok, we're all off the trip.")
			message_begin(MSG_ONE,gmsgFade,{0,0,0},id[0])
			write_short( 1<<1 ) // fade lasts this long duration
			write_short( 1<<1 ) // fade lasts this long hold time
			write_short( 1<<12 ) // fade type (in / out)
			write_byte( 0 ) // fade red
			write_byte( 0 ) // fade green
			write_byte( 0 ) // fade blue
			write_byte( 0 ) // fade alpha
		}
		all_lsd = 0	
		client_cmd(0,"default_fov 90")
	}
	return PLUGIN_CONTINUE
}


public coke_1(id[]){
	new cmd[16],dfov,a,b,c
	ccounter[id[0]] += 1
	if(is_user_alive(id[0])){
		c = random_num(0,100)
		if(c == 5){
			user_kill(id[0])
			new tname[32]
			get_user_name(id[0],tname,31)	
			client_print(0,print_chat,"[VIP] %s has died of a reaction to coke",tname)
		}
		new vec[3]
		get_user_origin(id[0],vec)
		new tname[32]
		Drugme(id[0])
		get_user_name(id[0],tname,31)	
		server_cmd("tspp_admin %s",tname)
		server_cmd("tspp_gslow %s 1.5",tname)
  		message_begin(MSG_ONE,gmsgShake,{0,0,0},id[0]) 
   		write_short(1<<14) // shake amount 
  		write_short(1<<12) // shake lasts this long 
  		write_short(1<<13) // shake noise frequency 
  		message_end() 
		dfov = random_num(10,120)
		format(cmd,15,"default_fov %d",dfov)
		client_cmd(id[0],cmd)
		if(moved[id[0]]){
			client_cmd(id[0],"-moveleft;-moveright;-forward;-back;-left;-right")
			moved[id[0]] = 0
		}
		b = random_num(0,8)
		if(b == 1){
			a = random_num(0,3)				
			client_cmd(id[0],moves[a])
			moved[id[0]] = 1
			new aimvec[3] 
			new velocityvec[3] 
			new length 	 
			new speed = 500 
			get_user_origin(id[0],aimvec,2) 
			velocityvec[0]=aimvec[0]-vec[0] 
			velocityvec[1]=aimvec[1]-vec[1] 
			velocityvec[2]=aimvec[2]-vec[2] 
			length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 
			velocityvec[0]=velocityvec[0]*speed/length 
			velocityvec[1]=velocityvec[1]*speed/length 
			velocityvec[2]=velocityvec[2]*speed/length 
		}
	}
	if(ccounter[id[0]] >= id[1]){
		if(is_coke[id[0]] == 1){
			new tname[32]
			get_user_name(id[0],tname,31)	
			StopDrug(id[0])
			client_print(0,print_chat,"[VIP] %s has quit coke for now",tname)
			//server_cmd("tspp_gslow %s 1.0",tname)
			//server_cmd("tspp_admin %s",tname)
		}
		is_coke[id[0]] = 0
		client_cmd(id[0],"default_fov 90")
	}
	return PLUGIN_CONTINUE
}



public coke_a(id[]){
	new cmd[16],dfov,a,b
	ccounter[0] += 1
	new iMaxPlayers = get_maxplayers()+1
	for (new i = 1; i <= iMaxPlayers; i++) {
		if(is_user_alive(i)){
		new tname[32]
		Drugme(i)
		get_user_name(id[0],tname,31)	
		server_cmd("tspp_admin %s",tname)
		server_cmd("tspp_gslow %s 1.5",tname)
		new vec[3]
		get_user_origin(id[0],vec)
  		message_begin(MSG_ONE,gmsgShake,{0,0,0},id[0]) 
   		write_short(1<<14) // shake amount 
  		write_short(1<<12) // shake lasts this long 
  		write_short(1<<13) // shake noise frequency 
  		message_end() 
		dfov = random_num(10,120)
		format(cmd,15,"default_fov %d",dfov)
		client_cmd(id[0],cmd)
		if(moved[id[0]]){
			client_cmd(id[0],"-moveleft;-moveright;-forward;-back;-left;-right")
			moved[id[0]] = 0
		}
		b = random_num(0,8)
		if(b == 1){
			a = random_num(0,3)				
			client_cmd(id[0],moves[a])
			moved[id[0]] = 1
			new aimvec[3] 
			new velocityvec[3] 
			new length 	 
			new speed = 500 
			get_user_origin(id[0],aimvec,2) 
			velocityvec[0]=aimvec[0]-vec[0] 
			velocityvec[1]=aimvec[1]-vec[1] 
			velocityvec[2]=aimvec[2]-vec[2] 
			length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 
			velocityvec[0]=velocityvec[0]*speed/length 
			velocityvec[1]=velocityvec[1]*speed/length 
			velocityvec[2]=velocityvec[2]*speed/length 
			// TE_MODEL from HL-SDK common/const.h 
			}
		}
	}
	if(ccounter[0] >= id[1]){
		for (new i = 1; i <= iMaxPlayers; i++) {
			if(moved[i])
				client_cmd(i,"-moveleft;-moveright;-forward;-back;-right;-left")
		}
		if(all_coke == 1){
			client_print(0,print_chat,"[VIP] Ok, we're not coke heads anymore.")
		}
		all_coke = 0	
		client_cmd(0,"default_fov 90")
	}
	return PLUGIN_CONTINUE
}


public crack_1(id[]){
	new cmd[16],dfov,a,b,c
	sccounter[id[0]] += 1
	if(is_user_alive(id[0])){
		Drugme(id[0])
		c = random_num(0,100)
		if(c == 5){
			user_kill(id[0])
			new tname[32]
			get_user_name(id[0],tname,31)	
			client_print(0,print_chat,"[VIP] %s has died of a reaction to crack",tname)
		}
		new vec[3]
		get_user_origin(id[0],vec)
		new tname[32]
		get_user_name(id[0],tname,31)	
		server_cmd("tspp_admin %s",tname)
		server_cmd("tspp_gslow %s 1.5",tname)
  		message_begin(MSG_ONE,gmsgShake,{0,0,0},id[0]) 
   		write_short(1<<14) // shake amount 
  		write_short(1<<12) // shake lasts this long 
  		write_short(1<<13) // shake noise frequency 
  		message_end() 
		new y1,x1
		x1 = random_num(-40,40)
		y1 = random_num(-40,40)
		//Smoke    
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 5 ) // 5
		write_coord(vec[0]+x1) 
		write_coord(vec[1]+y1) 
		write_coord(vec[2]+30) 
		write_short( smoke ) 
		write_byte( 30 )  // 10
		write_byte( 10 )  // 10
		message_end()
		dfov = random_num(10,120)
		format(cmd,15,"default_fov %d",dfov)
		client_cmd(id[0],cmd)
		if(moved[id[0]]){
			client_cmd(id[0],"-moveleft;-moveright;-forward;-back;-left;-right")
			moved[id[0]] = 0
		}
		b = random_num(0,8)
		if(b == 1){
			a = random_num(0,3)				
			client_cmd(id[0],moves[a])
			moved[id[0]] = 1
			new aimvec[3] 
			new velocityvec[3] 
			new length 	 
			new speed = 500 
			get_user_origin(id[0],aimvec,2) 
			velocityvec[0]=aimvec[0]-vec[0] 
			velocityvec[1]=aimvec[1]-vec[1] 
			velocityvec[2]=aimvec[2]-vec[2] 
			length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 
			velocityvec[0]=velocityvec[0]*speed/length 
			velocityvec[1]=velocityvec[1]*speed/length 
			velocityvec[2]=velocityvec[2]*speed/length 
		}
	}
	if(sccounter[id[0]] >= id[1]){
		if(is_crack[id[0]] == 1){
			new tname[32]
			get_user_name(id[0],tname,31)	
			StopDrug(id[0])
			client_print(0,print_chat,"[VIP] %s has quit crack for now.",tname)
			//server_cmd("tspp_gslow %s 1.0",tname)
			//server_cmd("tspp_admin %s",tname)
		}
		is_crack[id[0]] = 0
		client_cmd(id[0],"default_fov 90")
	}
	return PLUGIN_CONTINUE
}



public crack_a(id[]){
	new cmd[16],dfov,a,b
	sccounter[0] += 1
	new iMaxPlayers = get_maxplayers()+1
	for (new i = 1; i <= iMaxPlayers; i++) {
		if(is_user_alive(i)){
		Drugme(i)
		new tname[32]
		get_user_name(id[0],tname,31)	
		server_cmd("tspp_admin %s",tname)
		server_cmd("tspp_gslow %s 1.5",tname)
		new vec[3]
		get_user_origin(id[0],vec)
  		message_begin(MSG_ONE,gmsgShake,{0,0,0},id[0]) 
   		write_short(1<<14) // shake amount 
  		write_short(1<<12) // shake lasts this long 
  		write_short(1<<13) // shake noise frequency 
  		message_end() 
		new y1,x1
		x1 = random_num(-40,40)
		y1 = random_num(-40,40)
		//Smoke    
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 5 ) // 5
		write_coord(vec[0]+x1) 
		write_coord(vec[1]+y1) 
		write_coord(vec[2]+30) 
		write_short( smoke ) 
		write_byte( 30 )  // 10
		write_byte( 10 )  // 10
		message_end()
		dfov = random_num(10,120)
		format(cmd,15,"default_fov %d",dfov)
		client_cmd(id[0],cmd)
		if(moved[id[0]]){
			client_cmd(id[0],"-moveleft;-moveright;-forward;-back;-left;-right")
			moved[id[0]] = 0
		}
		b = random_num(0,8)
		if(b == 1){
			a = random_num(0,3)				
			client_cmd(id[0],moves[a])
			moved[id[0]] = 1
			new aimvec[3] 
			new velocityvec[3] 
			new length 	 
			new speed = 500 
			get_user_origin(id[0],aimvec,2) 
			velocityvec[0]=aimvec[0]-vec[0] 
			velocityvec[1]=aimvec[1]-vec[1] 
			velocityvec[2]=aimvec[2]-vec[2] 
			length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 
			velocityvec[0]=velocityvec[0]*speed/length 
			velocityvec[1]=velocityvec[1]*speed/length 
			velocityvec[2]=velocityvec[2]*speed/length 
			// TE_MODEL from HL-SDK common/const.h 
			}
		}
	}
	if(sccounter[0] >= id[1]){
		for (new i = 1; i <= iMaxPlayers; i++) {
			if(moved[i])
				client_cmd(i,"-moveleft;-moveright;-forward;-back;-right;-left")
		}
		if(all_crack == 1){
			client_print(0,print_chat,"[VIP] Ok, we're not crack heads anymore.")
		}
		all_crack = 0	
		client_cmd(0,"default_fov 90")
	}
	return PLUGIN_CONTINUE
}


public maryjane_1(id[]){
	new cmd[16],dfov,a,b
	mcounter[id[0]] += 1
	if(is_user_alive(id[0])){
		new vec[3]
		get_user_origin(id[0],vec)
		new tname[32]
		Drugme(id[0])
		get_user_name(id[0],tname,31)	
		server_cmd("tspp_admin %s",tname)
		server_cmd("tspp_gslow %s 0.8",tname)
  		message_begin(MSG_ONE,gmsgShake,{0,0,0},id[0]) 
   		write_short(1<<13) // shake amount 
  		write_short(1<<11) // shake lasts this long 
  		write_short(1<<13) // shake noise frequency 
  		message_end() 
		new y1,x1
		x1 = random_num(-40,40)
		y1 = random_num(-40,40)
		//Smoke    
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 5 ) // 5
		write_coord(vec[0]+x1) 
		write_coord(vec[1]+y1) 
		write_coord(vec[2]+30) 
		write_short( smoke ) 
		write_byte( 30 )  // 10
		write_byte( 10 )  // 10
		message_end()
		dfov = random_num(10,120)
		format(cmd,15,"default_fov %d",dfov)
		client_cmd(id[0],cmd)
		if(moved[id[0]]){
			client_cmd(id[0],"-moveleft;-moveright;-forward;-back;-left;-right")
			moved[id[0]] = 0
		}
		b = random_num(0,5)
		if(b == 1){
			a = random_num(0,3)				
			client_cmd(id[0],moves[a])
			moved[id[0]] = 1
			new aimvec[3] 
			new velocityvec[3] 
			new length 	 
			new speed = 500 
			get_user_origin(id[0],aimvec,2) 
			velocityvec[0]=aimvec[0]-vec[0] 
			velocityvec[1]=aimvec[1]-vec[1] 
			velocityvec[2]=aimvec[2]-vec[2] 
			length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 
			velocityvec[0]=velocityvec[0]*speed/length 
			velocityvec[1]=velocityvec[1]*speed/length 
			velocityvec[2]=velocityvec[2]*speed/length 
		}
	}
	if(mcounter[id[0]] >= id[1]){
		if(is_coke[id[0]] == 1){
			new tname[32]
			get_user_name(id[0],tname,31)	
			//server_cmd("tspp_gslow %s 1.0",tname)
			StopDrug(id[0])
			client_print(0,print_chat,"[VIP] %s has quit weed for now.",tname)
			message_begin(MSG_ONE,gmsgFade,{0,0,0},id[0])
			write_short( 0 ) // fade lasts this long duration
			write_short( 0 ) // fade lasts this long hold time
			write_short( 0 ) // fade type (in / out)
			write_byte( 0 ) // fade red
			write_byte( 0 ) // fade green
			write_byte( 0 ) // fade blue
			write_byte( 0 ) // fade alpha
		}
		is_maryjane[id[0]] = 0

		client_cmd(id[0],"default_fov 90")
	}
	return PLUGIN_CONTINUE
}

public maryjane_a(id[]){
	new cmd[16],dfov,a,b
	mcounter[0] += 1
	new iMaxPlayers = get_maxplayers()+1
	for (new i = 1; i <= iMaxPlayers; i++) {
		if(is_user_alive(i)){
		Drugme(i)
		new tname[32]
		get_user_name(id[0],tname,31)	
		server_cmd("tspp_gslow %s 0.8",tname)
		new vec[3]
		get_user_origin(id[0],vec)
  		message_begin(MSG_ONE,gmsgShake,{0,0,0},id[0]) 
   		write_short(1<<13) // shake amount 
  		write_short(1<<11) // shake lasts this long 
  		write_short(1<<13) // shake noise frequency 
  		message_end() 
		new y1,x1
		x1 = random_num(-40,40)
		y1 = random_num(-40,40)
		//Smoke    
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 5 ) // 5
		write_coord(vec[0]+x1) 
		write_coord(vec[1]+y1) 
		write_coord(vec[2]+30) 
		write_short( smoke ) 
		write_byte( 30 )  // 10
		write_byte( 10 )  // 10
		message_end()
		dfov = random_num(10,120)
		format(cmd,15,"default_fov %d",dfov)
		client_cmd(id[0],cmd)
		if(moved[id[0]]){
			client_cmd(id[0],"-moveleft;-moveright;-forward;-back;-left;-right")
			moved[id[0]] = 0
		}
		b = random_num(0,5)
		if(b == 1){
			a = random_num(0,3)				
			client_cmd(id[0],moves[a])
			moved[id[0]] = 1
			new aimvec[3] 
			new velocityvec[3] 
			new length 	 
			new speed = 500 
			get_user_origin(id[0],aimvec,2) 
			velocityvec[0]=aimvec[0]-vec[0] 
			velocityvec[1]=aimvec[1]-vec[1] 
			velocityvec[2]=aimvec[2]-vec[2] 
			length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2]) 
			velocityvec[0]=velocityvec[0]*speed/length 
			velocityvec[1]=velocityvec[1]*speed/length 
			velocityvec[2]=velocityvec[2]*speed/length 
			// TE_MODEL from HL-SDK common/const.h 
			}
		}
	}
	if(mcounter[0] >= id[1]){
		for (new i = 1; i <= iMaxPlayers; i++) {
			if(moved[i])
				client_cmd(i,"-moveleft;-moveright;-forward;-back;-right;-left")
		}
		if(all_maryjane == 1){
			message_begin(MSG_ONE,gmsgFade,{0,0,0},id[0])
			write_short( 1<<1 ) // fade lasts this long duration
			write_short( 1<<1 ) // fade lasts this long hold time
			write_short( 1<<12 ) // fade type (in / out)
			write_byte( 0 ) // fade red
			write_byte( 0 ) // fade green
			write_byte( 0 ) // fade blue
			write_byte( 0 ) // fade alpha
			client_print(0,print_chat,"[VIP] Ok, we're not coke heads anymore.")
		}
		all_maryjane = 0	
		client_cmd(0,"default_fov 90")
	}
	return PLUGIN_CONTINUE
}

public handle_botsayplugin(){
	new sarg2[192]
	read_args(sarg2,191)
	new arg1[8]
	read_argv(2,arg1,7)
	new id = str_to_num(arg1)
	if(is_user_bot(id)){
		new OnlySay[128]
		new len = strlen(sarg2)
		new start = contain(sarg2,":    ")
		copy(OnlySay,len-start+5,sarg2[start+5])
		if(equal(OnlySay,"/drink")){
			if(drugs_on == false)
				return PLUGIN_CONTINUE
			if(is_drunk[id] == 1)
				return PLUGIN_CONTINUE
			new idargs[2]
			idargs[0] = id
			idargs[1] = DRINKIN_TIME * 2
			is_drunk[id] = 1
			dcounter[id] = 0	
			set_task(0.5,"drinkin_1",0,idargs,2,"a",DRINKIN_TIME * 2)
			client_cmd(0,"play gnyso/L2_drink")
		}
		if(equal(OnlySay,"/smoke")){
			if(drugs_on == false)
				return PLUGIN_CONTINUE
			if(is_smoke[id] == 1)
				return PLUGIN_CONTINUE
			new idargs[2]
			idargs[0] = id
			idargs[1] = SMOKIN_TIME * 2
			is_smoke[id] = 1
			scounter[id] = 0	
			set_task(0.5,"smokin_1",0,idargs,2,"a",SMOKIN_TIME * 2)
			client_cmd(0,"play gnyso/L2_drink")
		}
		if(equal(OnlySay,"/takeLSD")){
			if(drugs_on == false)
				return PLUGIN_CONTINUE
			if(is_lsd[id] == 1)
				return PLUGIN_CONTINUE
			new idargs[2]
			idargs[0] = id
			idargs[1] = DRINKIN_TIME * 2
			is_lsd[id] = 1
			lcounter[id] = 0	
			set_task(5.0,"lsd_1",0,idargs,2,"a",LSDHIGH_TIME / 5)
			client_cmd(0,"play gnyso/L2_drink")
		}
		if(equal(OnlySay,"/snortcoke")){
			if(drugs_on == false)
				return PLUGIN_CONTINUE
			if(is_coke[id] == 1)
				return PLUGIN_CONTINUE
			new idargs[2]
			idargs[0] = id
			idargs[1] = COKEHIGH_TIME * 2
			is_coke[id] = 1
			ccounter[id] = 0	
			set_task(0.5,"coke_1",0,idargs,2,"a",COKEHIGH_TIME * 2)
			client_cmd(0,"play gnyso/L2_drink")
		}
		if(equal(OnlySay,"/smokeweed")){
			if(drugs_on == false)
				return PLUGIN_CONTINUE
			if(is_maryjane[id] == 1)
				return PLUGIN_CONTINUE
			new idargs[2]
			idargs[0] = id
			idargs[1] = COKEHIGH_TIME * 2
			is_maryjane[id] = 1
			mcounter[id] = 0	
			set_task(0.5,"maryjane_1",0,idargs,2,"a",MARYJANE_TIME * 2)
			client_cmd(0,"play gnyso/L2_drink")
		}
	}
	return PLUGIN_CONTINUE
}

public make_me_drunk(id){
	if(drugs_on == false){
		client_print(id, print_chat, "[VIP] Sorry, drinking has been disabled by admin")
		return PLUGIN_CONTINUE
	}
	if(is_drunk[id] == 1){
		client_print(id,print_chat,"[VIP] Sorry, I am already too drunk")
		return PLUGIN_HANDLED
	}
	new idargs[2]
	new player_name[32]
	get_user_name(id,player_name,31)
	idargs[0] = id
	idargs[1] = DRINKIN_TIME * 2
	is_drunk[id] = 1
	dcounter[id] = 0	
	cooldown_time[id]=1000
	set_task(0.5,"drinkin_1",0,idargs,2,"a",DRINKIN_TIME * 2)
	client_print(id,print_chat,"[VIP] %s is drunk for 10 seconds.", player_name)
	client_cmd(0,"play gnyso/L2_drink")
	return PLUGIN_CONTINUE
}

public make_me_smoke(id){
	if(drugs_on == false){
		client_print(id, print_chat, "[VIP] Sorry, smoking has been disabled by admin")
		return PLUGIN_CONTINUE
	}
	if(is_smoke[id] == 1){
		client_print(id,print_chat,"[VIP] Sorry, I am already smoking")
		return PLUGIN_HANDLED
	}
	new idargs[2]
	new player_name[32]
	get_user_name(id,player_name,31)
	idargs[0] = id
	idargs[1] = SMOKIN_TIME * 2
	is_smoke[id] = 1
	scounter[id] = 0	
	cooldown_time[id]=1000
	set_task(0.5,"smokin_1",0,idargs,2,"a",SMOKIN_TIME * 2)
	client_print(id,print_chat,"[VIP] %s is smoking for 10 seconds.", player_name)
	client_cmd(0,"play gnyso/L2_drink")
	return PLUGIN_CONTINUE
}

public make_me_takelsd(id){
	if(drugs_on == false){
		client_print(id, print_chat, "[AMX] Sorry, LSD has been disabled by admin")
		return PLUGIN_CONTINUE
	}
	if(is_lsd[id] == 1){
		client_print(id,print_chat,"[AMX] Sorry, I am already on LSD")
		return PLUGIN_HANDLED
	}
	new idargs[2]
	idargs[0] = id
	idargs[1] = LSDHIGH_TIME * 2
	is_lsd[id] = 1
	lcounter[id] = 0	
	cooldown_time[id]=1000
	set_task(2.0,"lsd_1",0,idargs,2,"a",LSDHIGH_TIME * 2)
	client_print(id,print_chat,"[AMX] Ok, you are tripping for for 10 seconds")
	client_cmd(0,"play gnyso/L2_drink")
	return PLUGIN_CONTINUE
}

public make_me_snortcoke(id){
	if(drugs_on == false){
		client_print(id, print_chat, "[AMX] Sorry, Cocaine has been disabled by admin")
		return PLUGIN_CONTINUE
	}
	if(is_coke[id] == 1){
		client_print(id,print_chat,"[AMX] Sorry, I am already on Coke")
		return PLUGIN_HANDLED
	}
	new idargs[2]
	idargs[0] = id
	idargs[1] = COKEHIGH_TIME * 2
	is_coke[id] = 1
	ccounter[id] = 0
	new player_name[32]
	get_user_name(id,player_name,31)	
	cooldown_time[id]=1000
	set_task(0.5,"coke_1",0,idargs,2,"a",COKEHIGH_TIME * 2)
	client_print(id,print_chat,"[VIP] %s is on a coke high for 10 seconds.", player_name)
	client_cmd(0,"play gnyso/L2_drink")
	return PLUGIN_CONTINUE
}

public make_me_smokecrack(id){
	if(drugs_on == false){
		client_print(id, print_chat, "[VIP] Sorry, crack has been disabled by admin")
		return PLUGIN_CONTINUE
	}
	if(is_crack[id] == 1){
		client_print(id,print_chat,"[VIP] Sorry, I am already on Crack")
		return PLUGIN_HANDLED
	}
	new idargs[2]
	idargs[0] = id
	idargs[1] = COKEHIGH_TIME * 2
	is_crack[id] = 1
	sccounter[id] = 0	
	new player_name[32]
	get_user_name(id,player_name,31)
	cooldown_time[id]=1000
	set_task(0.5,"crack_1",0,idargs,2,"a",COKEHIGH_TIME * 2)
	client_print(id,print_chat,"[VIP] %s is on a crack high for 10 seconds", player_name)
	client_cmd(0,"play gnyso/L2_drink")
	return PLUGIN_CONTINUE
}

public make_me_smokeweed(id){
	if(drugs_on == false){
		client_print(id, print_chat, "[AMX] Sorry, Weed has been disabled by admin")
		return PLUGIN_CONTINUE
	}
	if(is_maryjane[id] == 1){
		client_print(id,print_chat,"[AMX] Sorry, I am already on Weed")
		return PLUGIN_HANDLED
	}
	new idargs[2]
	idargs[0] = id
	idargs[1] = MARYJANE_TIME * 2
	is_lsd[id] = 1
	mcounter[id] = 0	
	cooldown_time[id]=1000
	set_task(0.5,"maryjane_1",0,idargs,2,"a",MARYJANE_TIME * 2)
	client_print(id,print_chat,"[AMX] Ok, you are now high for 10 seconds")
	client_cmd(0,"play gnyso/L2_drink")
	return PLUGIN_CONTINUE
}

public admin_drugs(id,level,cid){
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED

	if (read_argc() < 2){
		new onoff[4]
		if(drugs_on == true){
			copy(onoff, 4, "ON")
		}else{
			copy(onoff, 4, "OFF")
		}
		client_print(id,print_console,"[AMX] Usage: amx_drugs < on | off >     Currently: %s", onoff)
		return PLUGIN_HANDLED
	}

	new arg[10]
	read_argv(1,arg,10)

	if ( (equali(arg,"on", 2)) || (equal(arg,"1", 1)) ){
		drugs_on = true
		console_print(id,"[AMX] Drug mode is now ON")
		client_print(0,print_chat,"[AMX] Admin has turned Drug mode ON")
	}else{
		drugs_on = false
		console_print(id,"[AMX] Drug mode is now OFF")
		client_print(0,print_chat,"[AMX] Admin has turned Drug mode OFF")
	}

	new authid[16],name[32]
	get_user_authid(id,authid,16)
	get_user_name(id,name,32)

	log_to_file("addons/amx/admin.log","^"%s<%d><%s><>^" drugmod_mode %s",name,get_user_userid(id),authid,arg)

	return PLUGIN_HANDLED
}

public amx_drugs_d(id,level,cid){
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED

	if(drugs_on == false){
		ejl_vault("WRITE","DRUG","off")
		console_print(id,"[AMX] Drugs mode OFF   is now the default.")
	}else{
		ejl_vault("WRITE","DRUG","on")
		console_print(id,"[AMX] Drugs mode ON    is now the default.")
	}

	new authid[16],name[32]
	get_user_authid(id,authid,16)
	get_user_name(id,name,32)

	log_to_file("addons/amx/admin.log","^"%s<%d><%s><>^" drugmod_d",name,get_user_userid(id),authid)

	return PLUGIN_HANDLED
}












public cmdCancelVote(id, level, cid)
{
	if (!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED

	if (task_exists(99889988, 1))
	{
		new authid[32], name[MAX_NAME_LENGTH]
		
		get_user_authid(id, authid, charsmax(authid))
		get_user_name(id, name, charsmax(name))
		log_amx("Vote: ^"%s<%d><%s><>^" cancel vote session", name, get_user_userid(id), authid)
	
		new msg[256];
		for (new i = 1; i <= MaxClients; i++)
		{
			if (is_user_connected(i) && !is_user_bot(i))
			{
				// HACK: ADMIN_CANC_VOTE_{1,2} keys were designed very poorly.  Remove all : and %s in it.
				LookupLangKey(msg, charsmax(msg), "ADMIN_CANC_VOTE_1", i);
				replace_all(msg, charsmax(msg), "%s", "");
				replace_all(msg, charsmax(msg), ":", "");
				trim(msg);
				show_activity_id(i, id, name, msg);
			}
		}
		
		console_print(id, "%L", id, "VOTING_CANC")
		client_print(0,print_chat,"%L",LANG_PLAYER,"VOTING_CANC")
		remove_task(99889988, 1)
		set_cvar_float("amx_last_voting", get_gametime())
	}
	else
		console_print(id, "%L", id, "NO_VOTE_CANC")

	return PLUGIN_HANDLED
}

public delayedExec(cmd[])
{
	server_cmd("%s", cmd)
}

public autoRefuse()
{
	log_amx("Vote: %L", "en", "RESULT_REF")
	client_print(0, print_chat, "%L", LANG_PLAYER, "RESULT_REF")
}

public actionResult(id, key)
{
	remove_task(4545454)
	
	switch (key)
	{
		case 0:
		{
			set_task(2.0, "delayedExec", 0, g_Execute, g_execLen)
			log_amx("Vote: %L", "en", "RES_ACCEPTED")
			client_print(0, print_chat, "%L", LANG_PLAYER, "RES_ACCEPTED")
		}
		case 1: autoRefuse()
	}
	
	return PLUGIN_HANDLED
}

public checkVotes()
{
	new best = 0
	
	if (!g_yesNoVote)
	{
		for (new a = 0; a < 4; ++a)
			if (g_voteCount[a] > g_voteCount[best])
		
		best = a
	}

	new votesNum = g_voteCount[0] + g_voteCount[1] + g_voteCount[2] + g_voteCount[3]
	new iRatio = votesNum ? floatround(g_voteRatio * float(votesNum), floatround_ceil) : 1
	new iResult = g_voteCount[best]
	new players[MAX_PLAYERS], pnum, i
	
	get_players(players, pnum, "c")
	
	if (iResult < iRatio)
	{
		new lVotingFailed[64]
		
		for (i = 0; i < pnum; i++)
		{
			format(lVotingFailed, 63, "%L", players[i], "VOTING_FAILED")
			if (g_yesNoVote)
				client_print(players[i], print_chat, "%L", players[i], "VOTING_RES_1", lVotingFailed, g_voteCount[0], g_voteCount[1], iRatio)
			else
				client_print(players[i], print_chat, "%L", players[i], "VOTING_RES_2", lVotingFailed, iResult, iRatio)
		}
		
		format(lVotingFailed, 63, "%L", "en", "VOTING_FAILED")
		log_amx("Vote: %s (got ^"%d^") (needed ^"%d^")", lVotingFailed, iResult, iRatio)
		
		return PLUGIN_CONTINUE
	}
	format(g_Display, charsmax(g_Display), g_Answer_display, g_optionName[best])
	g_execLen = format(g_Execute, charsmax(g_Execute), g_Answer, g_optionName[best]) + 1
	
	if (g_execResult)
	{
		g_execResult = false
		
		if (is_user_connected(g_voteCaller))
		{
			new menuBody[512], lTheResult[32], lYes[16], lNo[16]
			
			format(lTheResult, charsmax(lTheResult), "%L", g_voteCaller, "THE_RESULT")
			format(lYes, charsmax(lYes), "%L", g_voteCaller, "YES")
			format(lNo, charsmax(lNo), "%L", g_voteCaller, "NO")
			
			new len = format(menuBody, charsmax(menuBody), g_coloredMenus ? "\y%s: \w%s^n^n" : "%s: %s^n^n", lTheResult, g_Display)
			
			len += format(menuBody[len], charsmax(menuBody) - len, g_coloredMenus ? "\y%L^n\w" : "%L^n", g_voteCaller, "WANT_CONTINUE")
			format(menuBody[len], charsmax(menuBody) - len, "^n1. %s^n2. %s", lYes, lNo)
			show_menu(g_voteCaller, 0x03, menuBody, 10, "The result: ")
			set_task(10.0, "autoRefuse", 4545454)
		}
		else
			set_task(2.0, "delayedExec", 0, g_Execute, g_execLen)
		
	}
	
	new lVotingSuccess[32]
	
	for (i = 0; i < pnum; i++)
	{
		format(lVotingSuccess, charsmax(lVotingSuccess), "%L", players[i], "VOTING_SUCCESS")
		client_print(players[i], print_chat, "%L", players[i], "VOTING_RES_3", lVotingSuccess, iResult, iRatio, g_Execute)
	}
	
	format(lVotingSuccess, charsmax(lVotingSuccess), "%L", "en", "VOTING_SUCCESS")
	log_amx("Vote: %s (got ^"%d^") (needed ^"%d^") (result ^"%s^")", lVotingSuccess, iResult, iRatio, g_Execute)
	//start_cooldown(g_voteCaller)
	return PLUGIN_CONTINUE
}

public voteCount(id, key)
{
	if (get_cvar_num("amx_vote_answers"))
	{
		new name[MAX_NAME_LENGTH]
		get_user_name(id, name, charsmax(name))
		
		if (g_yesNoVote)
			client_print(0, print_chat, "%L", LANG_PLAYER, key ? "VOTED_AGAINST" : "VOTED_FOR", name)
		else
			client_print(0, print_chat, "%L", LANG_PLAYER, "VOTED_FOR_OPT", name, key + 1)
	}
	++g_voteCount[key]
	
	return PLUGIN_HANDLED
}

public cmdVoteMap(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new Float:voting = get_cvar_float("amx_last_voting")
	if (voting > get_gametime())
	{
		console_print(id, "%L", id, "ALREADY_VOTING")
		return PLUGIN_HANDLED
	}
	/*
	if (voting && voting + get_cvar_float("amx_vote_delay") > get_gametime())
	{
		console_print(id, "%L", id, "VOTING_NOT_ALLOW")
		return PLUGIN_HANDLED
	}
	*/
	new argc = read_argc()
	if (argc > 5) argc = 5
	
	g_validMaps = 0
	g_optionName[0][0] = 0
	g_optionName[1][0] = 0
	g_optionName[2][0] = 0
	g_optionName[3][0] = 0
	
	for (new i = 1; i < argc; ++i)
	{
		read_argv(i, g_optionName[g_validMaps], 31)
		
		if (is_map_valid(g_optionName[g_validMaps]))
			g_validMaps++
	}
	
	if (g_validMaps == 0)
	{
		new lMaps[16]
		
		format(lMaps, charsmax(lMaps), "%L", id, (argc == 2) ? "MAP_IS" : "MAPS_ARE")
		console_print(id, "%L", id, "GIVEN_NOT_VALID", lMaps)
		return PLUGIN_HANDLED
	}

	new menu_msg[256], len = 0
	new keys = 0
	
	if (g_validMaps > 1)
	{
		keys = MENU_KEY_0
		len = format(menu_msg, charsmax(menu_msg), g_coloredMenus ? "\y%L: \w^n^n" : "%L: ^n^n", LANG_SERVER, "CHOOSE_MAP")
		new temp[128]
		
		for (new a = 0; a < g_validMaps; ++a)
		{
			format(temp, charsmax(temp), "%d.  %s^n", a+1, g_optionName[a])
			len += copy(menu_msg[len], charsmax(menu_msg) - len, temp)
			keys |= (1<<a)
		}
		
		format(menu_msg[len], charsmax(menu_msg) - len, "^n0.  %L", LANG_SERVER, "NONE")
		g_yesNoVote = 0
	} else {
		new lChangeMap[32], lYes[16], lNo[16]
		
		format(lChangeMap, charsmax(lChangeMap), "%L", LANG_SERVER, "CHANGE_MAP_TO")
		format(lYes, charsmax(lYes), "%L", LANG_SERVER, "YES")
		format(lNo, charsmax(lNo), "%L", LANG_SERVER, "NO")
		format(menu_msg, charsmax(menu_msg), g_coloredMenus ? "\y%s %s?\w^n^n1.  %s^n2.  %s" : "%s %s?^n^n1.  %s^n2.  %s", lChangeMap, g_optionName[0], lYes, lNo)
		keys = MENU_KEY_1|MENU_KEY_2
		g_yesNoVote = 1
	}
	
	new authid[32], name[MAX_NAME_LENGTH]
	
	get_user_authid(id, authid, charsmax(authid))
	get_user_name(id, name, charsmax(name))
	
	if (argc == 2)
		log_amx("Vote: ^"%s<%d><%s><>^" vote map (map ^"%s^")", name, get_user_userid(id), authid, g_optionName[0])
	else
		log_amx("Vote: ^"%s<%d><%s><>^" vote maps (map#1 ^"%s^") (map#2 ^"%s^") (map#3 ^"%s^") (map#4 ^"%s^")", name, get_user_userid(id), authid, g_optionName[0], g_optionName[1], g_optionName[2], g_optionName[3])

	new msg[256];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (is_user_connected(i) && !is_user_bot(i))
		{
			// HACK: ADMIN_VOTE_MAP_{1,2} keys were designed very poorly.  Remove all : and %s in it.
			LookupLangKey(msg, charsmax(msg), "ADMIN_VOTE_MAP_1", i);
			replace_all(msg, charsmax(msg), "%s", "");
			replace_all(msg, charsmax(msg), ":", "");
			trim(msg);
			show_activity_id(i, id, name, msg);
		}
	}

	g_execResult = true
	new Float:vote_time = get_cvar_float("amx_vote_time") + 2.0
	
	set_cvar_float("amx_last_voting", get_gametime() + vote_time)
	g_voteRatio = get_cvar_float("amx_votemap_ratio")
	g_Answer = "changelevel %s"
	show_menu(0, keys, menu_msg, floatround(vote_time), (g_validMaps > 1) ? "Choose map: " : "Change map to ")
	set_task(vote_time, "checkVotes", 99889988)
	g_voteCaller = id
	console_print(id, "%L", id, "VOTING_STARTED")
	g_voteCount = {0, 0, 0, 0}
	
	return PLUGIN_HANDLED
}

public cmdVote(id, level, cid)
{
	if (!cmd_access(id, level, cid, 4))
		return PLUGIN_HANDLED
	
	new Float:voting = get_cvar_float("amx_last_voting")
	if (voting > get_gametime())
	{
		console_print(id, "%L", id, "ALREADY_VOTING")
		return PLUGIN_HANDLED
	}
	
	if (voting && voting + get_cvar_float("amx_vote_delay") > get_gametime())
	{
		console_print(id, "%L", id, "VOTING_NOT_ALLOW")
		return PLUGIN_HANDLED
	}

	new quest[48]
	read_argv(1, quest, charsmax(quest))
	
	trim(quest);
	
	if (containi(quest, "sv_password") != -1 || containi(quest, "rcon_password") != -1)
	{
		console_print(id, "%L", id, "VOTING_FORBIDDEN")
		return PLUGIN_HANDLED
	}
	
	new count=read_argc();

	for (new i=0;i<4 && (i+2)<count;i++)
	{
		read_argv(i+2, g_optionName[i], charsmax(g_optionName[]));
	}

	new authid[32], name[MAX_NAME_LENGTH]
	
	get_user_authid(id, authid, charsmax(authid))
	get_user_name(id, name, charsmax(name))
	log_amx("Vote: ^"%s<%d><%s><>^" vote custom (question ^"%s^") (option#1 ^"%s^") (option#2 ^"%s^")", name, get_user_userid(id), authid, quest, g_optionName[0], g_optionName[1])

	new msg[256];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (is_user_connected(i) && !is_user_bot(i))
		{
			// HACK: ADMIN_VOTE_CUS_{1,2} keys were designed very poorly.  Remove all : and %s in it.
			LookupLangKey(msg, charsmax(msg), "ADMIN_VOTE_CUS_1", i);
			replace_all(msg, charsmax(msg), "%s", "");
			replace_all(msg, charsmax(msg), ":", "");
			trim(msg);
			show_activity_id(i, id, name, msg);
		}
	}

	new menu_msg[512], lVote[16]
	
	format(lVote, charsmax(lVote), "%L", LANG_SERVER, "VOTE")
	
	count-=2;
	if (count>4)
	{
		count=4;
	}
	// count now shows how many options were listed
	new keys=0;
	for (new i=0;i<count;i++)
	{
		keys |= (1<<i);
	}
	
	new len=formatex(menu_msg, charsmax(menu_msg), g_coloredMenus ? "\y%s: %s\w^n^n" : "%s: %s^n^n", lVote, quest);
	
	for (new i=0;i<count;i++)
	{
		len+=formatex(menu_msg[len], charsmax(menu_msg) - len ,"%d.  %s^n",i+1,g_optionName[i]);
	}
	g_execResult = false
	
	new Float:vote_time = get_cvar_float("amx_vote_time") + 2.0
	
	set_cvar_float("amx_last_voting", get_gametime() + vote_time)
	g_voteRatio = get_cvar_float("amx_vote_ratio")
	replace_all(quest, charsmax(quest), "%", "");
	format(g_Answer, charsmax(g_Answer), "%s - ^"%%s^"", quest)
	show_menu(0, keys, menu_msg, floatround(vote_time), "Vote: ")
	set_task(vote_time, "checkVotes", 99889988)
	g_voteCaller = id
	console_print(id, "%L", id, "VOTING_STARTED")
	g_voteCount = {0, 0, 0, 0}
	g_yesNoVote = 0
	
	return PLUGIN_HANDLED
}

public cmdVoteKickBan(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new Float:voting = get_cvar_float("amx_last_voting")
	if (voting > get_gametime())
	{
		console_print(id, "%L", id, "ALREADY_VOTING")
		return PLUGIN_HANDLED
	}
	/*
	if (voting && voting + get_cvar_float("amx_vote_delay") > get_gametime())
	{
		console_print(id, "%L", id, "VOTING_NOT_ALLOW")
		return PLUGIN_HANDLED
	}
	*/
	//start_cooldown(id);
	new cmd[32]
	
	read_argv(0, cmd, charsmax(cmd))
	
	new voteban = equal(cmd, "amx_voteban_player_name")
	new arg[32]
	read_argv(1, arg, charsmax(arg))
	
	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)
	new imname[33]
	get_user_name(player, imname, charsmax(imname))
		
	if (!player)
		return PLUGIN_HANDLED
	
	if (voteban && is_user_bot(player))
	{
		console_print(id, "%L", id, "ACTION_PERFORMED", imname)
		return PLUGIN_HANDLED
	}

	new keys = MENU_KEY_1|MENU_KEY_2
	new menu_msg[256], lYes[16], lNo[16], lKickBan[16]
	
	format(lYes, charsmax(lYes), "%L", LANG_SERVER, "YES") 
	format(lNo, charsmax(lNo), "%L", LANG_SERVER, "NO")
	format(lKickBan, charsmax(lKickBan), "%L", LANG_SERVER, voteban ? "BAN" : "KICK")
	ucfirst(lKickBan)
	get_user_name(player, arg, charsmax(arg))
	format(menu_msg, charsmax(menu_msg), g_coloredMenus ? "\y%s %s for %s?\w^n^n1.  %s^n2.  %s" : "%s %s for %s?^n^n1.  %s^n2.  %s", lKickBan, arg, ban_reason, lYes, lNo)
	g_yesNoVote = 1
	
	
	if (voteban)
	{
		get_user_authid(player, g_optionName[0], charsmax(g_optionName[]));
		
		// Do the same check that's in plmenu to determine if this should be an IP ban instead
		if (equal("4294967295", g_optionName[0])
			|| equal("HLTV", g_optionName[0])
			|| equal("STEAM_ID_LAN", g_optionName[0])
			|| equali("VALVE_ID_LAN", g_optionName[0]))
		{
			get_user_ip(player, g_optionName[0], charsmax(g_optionName[]), 1);
			
		}

	}
	else
	{
		num_to_str(get_user_userid(player), g_optionName[0], charsmax(g_optionName[]))
	}
	
	new authid[32], name[MAX_NAME_LENGTH]
	
	get_user_authid(id, authid, charsmax(authid))
	get_user_name(id, name, charsmax(name))
	log_amx("Vote: ^"%s<%d><%s><>^" vote %s (target ^"%s^")", name, get_user_userid(id), authid, voteban ? "ban" : "kick", arg)

	new msg[256];
	new right[256];
	new dummy[1];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (is_user_connected(i) && !is_user_bot(i))
		{
			formatex(lKickBan, charsmax(lKickBan), "%L", i, voteban ? "BAN" : "KICK");
			
			LookupLangKey(msg, charsmax(msg), "ADMIN_VOTE_FOR_1", i);
			strtok(msg, dummy, 0, right, charsmax(right), ':');
			trim(right);
			show_activity_id(i, id, name, right, lKickBan, arg);
		}
	}

	g_execResult = true
	
	new Float:vote_time = get_cvar_float("amx_vote_time") + 2.0
	
	set_cvar_float("amx_last_voting", get_gametime() + vote_time)
	g_voteRatio = get_cvar_float(voteban ? "amx_voteban_ratio" : "amx_votekick_ratio")

	if (voteban)
	{
		
			format(g_Answer_display, charsmax(g_Answer_display), "Ban %s for 30 Minutes, for %s?",imname,ban_reason)
			if(equal(ban_reason,"Abusing"))
				g_Answer = "amx_ban 30 %s Abusing";
			if(equal(ban_reason,"Laming the gameplay"))
				g_Answer = "amx_ban 30 %s Laming the gameplay";
			if(equal(ban_reason,"Cheating"))
				g_Answer = "amx_ban 30 %s Cheating";
			if(equal(ban_reason,"Spamming in mic/chat"))
				g_Answer = "amx_ban 30 %s Spamming in mic/chat";
			if(equal(ban_reason,"Swearing/Insulting"))
				g_Answer = "amx_ban 30 %s Swearing/Insulting";
			
	}
	else
	{
		format(g_Answer_display, charsmax(g_Answer_display), "Kick %s for %s?",imname,ban_reason)
		g_Answer = "kick #%s";
	}
	show_menu(0, keys, menu_msg, floatround(vote_time), voteban ? "Ban " : "Kick ")
	if(pm_sound[0])
		client_cmd(0, "speak ^"sound/%s^"", pm_sound);
	set_task(vote_time, "checkVotes", 99889988)
	g_voteCaller = id
	console_print(id, "%L", id, "VOTING_STARTED")
	g_voteCount = {0, 0, 0, 0}
	
	return PLUGIN_HANDLED
}















public set_speed(id)
{
	new szName[33];
	get_user_name(id, szName, 32)
	client_cmd(id,"amx_speed %s ON 125",szName)
	cooldown_time[id]=1000
	client_print(0,print_chat,"[VIP] Speed of %s increased by 25% for 15 seconds.",szName)
	cooldown_time[id]=1000
	set_task(15.0,"reset_speed",id);
}

public reset_speed(id)
{
	
	new szName[33];
	get_user_name(id, szName, 32)
	client_cmd(id,"amx_speed %s OFF",szName)
	client_print(0,print_chat,"[VIP] Speed of %s restored back to normal.",szName)
	start_cooldown(id);
}


public set_gravity(id)
{
	set_user_gravity(id,0.625);
	cooldown_time[id]=1000
	client_print(id,print_chat,"[VIP] Gravity set to 500.");
	set_task(25.0,"reset_gravity",id);
}

public reset_gravity(id)
{
	set_user_gravity(id,1.0); //default gravity
	client_print(id,print_chat,"[VIP] Gravity set to 800.");
	start_cooldown(id);
}

public set_full_health(id)
{
	set_user_health(id,100); 
	client_print(id,print_chat,"[VIP] Full HP restored.");
	start_cooldown(id);
}


public slapMenu(id)
{
    new SlapPlayer = menu_create ("Slap Menu", "HandleSlap")

    new num, players[32], tempid, szTempID [10], tempname [32]
    get_players (players, num, "a")

    for (new i = 0; i < num; i++)
    {
        tempid = players [ i ]

        get_user_name (tempid, tempname, 31)
        num_to_str (tempid, szTempID, 9)
        menu_additem (SlapPlayer, tempname, szTempID, 0)
    }

    menu_display (id, SlapPlayer)
    return PLUGIN_HANDLED
}

public HandleSlap(id, menu, item)
{
    if(item == MENU_EXIT)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED

    }
    
    new data[6], name[64]
    new access, callback
    new szName[33], szPlayerName[33]
    menu_item_getinfo (menu, item, access, data, 5, name, 63, callback)
    new tempid = str_to_num (data)
    
    get_user_name(id, szName, 32)
    get_user_name(tempid, szPlayerName, 32)
    client_print(id, print_chat, "[VIP] You have just slapped %s.", szPlayerName)
    client_print(id, print_chat, "You have been slapped hard by VIP Player %s.", szName)
    //ColorChat(0, GREY, "%s ^4%s^3 just slapped ^4%s^3!", prefix, szName, szPlayerName)
    user_slap(tempid, 0, 0)
    start_cooldown(id)

    
    return PLUGIN_CONTINUE
}

public cooldown(id)
{
	cooldown_time[id]--;
	if(cooldown_time[id]>0)
		set_task(1.0,"cooldown",id);
}

public start_cooldown(id)
{
	cooldown_time[id]=(COOLDOWN_TIME_VALUE + 1);
	cooldown(id);
}

