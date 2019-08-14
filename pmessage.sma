/*Change Log
v1.2 - (Initiated by WeeKenD)
1) Added sender's and receiver's name in private message, so that the sender comes to know actually whom the message was sent to.


v1.1 - (Initiated by DusT)
1) Added command say /pm nick message 
2) Added command say /block nick
3) Added command say /admin message
4) Added log file to store private messages shared between players and PM Ban History.

v1.0 - 
1) Added command pm nick message
2) Added command pm_block nick
3) Added command pm_menu OR say /pm to open PM Menu
4) Added command /pageadmin
5) Added command admin_pm
6) Added command pm_ban
7) Sound for all Private messages
8) Ghosting check is implemented
*/
#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Private Messaging"
#define VERSION "1.2"
#define AUTHOR "Saqlain"

#define ADMIN_FLAG 	ADMIN_BAN //access flag 'd' required

#define INVALIDPLAYERMENU		

new g_maxClients

new toggle_pcvar
new toggle_log
new toggleCache
new log_value

new pm_sound[32]
new const LogFile[ ]   = "private_messages.log";


new onBits[33]
new bannedBits[33]
new blockList[33][33]	

public plugin_precache()
{
	new sound_pcvar = register_cvar("pm_sound", "buttons/bell1.wav")
	get_pcvar_string(sound_pcvar, pm_sound, charsmax(pm_sound) )
	
	if(pm_sound[0]) 
		precache_sound(pm_sound)
}
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	toggle_pcvar = register_cvar("private_message", "0")
	toggle_log = register_cvar("pm_log", "0")
	register_concmd("pm", "cmdConPM", 0, "[user] [message]")
	register_concmd("pm_menu", "cmdPMmenu", 0, "-Opens the Private Message client menu")
	register_concmd("pm_block", "cmdBlock", 0, "[user] -Blocks specified user")
	register_concmd("admin_pm", "cmdAdminPM", ADMIN_FLAG, "-Sends PM to user as admin, overriding any block or disable")
	register_concmd("pm_ban", "cmdAdminBan", ADMIN_FLAG, "[user] -Bans the specified user")
	
	register_clcmd("say", "client_say_cmd", 0, "-Opens the Private Message client menu")
	register_clcmd("say_team", "client_say_cmd", 0, "-Opens the Private Message client menu")
	register_clcmd("say /pageadmin", "pageAdmin", -1, "-Pages all admins")
	
	
	register_dictionary("pmessage.txt")
	
	g_maxClients = get_maxplayers()
	
	toggleCache = get_pcvar_num(toggle_pcvar)	
	
	createMainMenu()
}
public client_connect(id)
{
	onBits[id]=1;
	bannedBits[id]=0;
	for(new i = 1; i <= g_maxClients; i++)
		blockList[id][i] = 0;
}
new g_mainMenu
createMainMenu()
{
	g_mainMenu = menu_create("Private Message Menu", "menuHandler")
	
	menu_additem(g_mainMenu, "Toggle Private Messages", "1", 0)
	menu_additem(g_mainMenu, "Block User", "2", 0)
	menu_additem(g_mainMenu, "Page Admin", "3", 0)
	menu_additem(g_mainMenu, "Help", "4", 0)
	menu_additem(g_mainMenu, "Ban User (admin)", "5", ADMIN_FLAG)
	
	menu_setprop(g_mainMenu, MPROP_EXIT, MEXIT_ALL)

	return PLUGIN_CONTINUE
}


public client_say_cmd(id, level, cid)
{
	if(toggleCache == -1)
		return PLUGIN_CONTINUE
	
	new sString[96], message_admin[32]
	new sOutput[3][32]
	read_args(sString, charsmax(sString))
	remove_quotes(sString)
	if(equali(sString, "/pm"))
	{
		menu_display(id, g_mainMenu, 0)	
		return PLUGIN_HANDLED
	}
	str_explode(sString, ' ', sOutput, 2, 31)
	if(equali(sOutput[0], "/pm"))
	{
		str_explode(sString, ' ', sOutput, 3, 31)
	
		new player = cmd_target(id, sOutput[1], CMDTARGET_NO_BOTS)
	
		if(!player) 
		{
			client_print(id, print_console, "%L", id, "INVALID_PLAYER", sOutput[1])
		}
		else
			printMessage(player, id, sOutput[2])

	}
	if(equali(sOutput[0], "/block"))
	{
		new player = cmd_target(id, sOutput[1], CMDTARGET_NO_BOTS)
	
		if(!player) 
		{
			client_print(id, print_console, "%L", id, "INVALID_PLAYER", sOutput[1])
		}
		else
			blockUser(id, player)

	}
	if(equali(sOutput[0], "/admin"))
	{
		formatex(message_admin,charsmax(message_admin),"[TO ADMIN] %s",sOutput[1])
		
		new players[32], num
		get_players(players, num, "ch")
			
		for(new i = 0; i < num; i++)
		{	
			if(access(players[i], ADMIN_FLAG) )
				printMessage(players[i], id, message_admin)
		}	
	}
	return PLUGIN_CONTINUE
}	

public cmdConPM(id, level, cid)	// pm [user] [message]
{
	if(toggleCache == -1)
		return PLUGIN_HANDLED
	
		
	new args[300]; read_args(args, charsmax(args))
	remove_quotes(args)
	new target[32], message[192] 
		
	strbreak(args, target, charsmax(target), message, charsmax(message) )
	
		
	new player = cmd_target(id, target, CMDTARGET_NO_BOTS)
	
	if(!player) 
	{
		client_print(id, print_console, "%L", id, "INVALID_PLAYER", target)
	}
	else
		printMessage(player, id, message)
	
	return PLUGIN_HANDLED
}
public cmdBlock(id, level, cid)		
{
	if(!cmd_access(id, level, cid, 2) || toggleCache == -1)
		return PLUGIN_HANDLED
	
		
	new target[32]; read_argv(1, target, charsmax(target) )
	
		
	new player = cmd_target(id, target, CMDTARGET_NO_BOTS)
	
	
	if(!player) 
	{
		
		client_print(id, print_console, "%L", id, "INVALID_PLAYER", target) 
	}
	else
		blockUser(id, player)
	
	return PLUGIN_HANDLED
}
public pageAdmin(id)		
{
	if(toggleCache == -1)
		return PLUGIN_CONTINUE
		
	new players[32], num
	get_players(players, num, "ch")
		
	for(new i = 0; i < num; i++)
	{	
		if(access(players[i], ADMIN_FLAG) )
			printMessage(players[i], id, "[TO ADMIN]")
	}
	return PLUGIN_HANDLED
}



public cmdAdminPM(id, level, cid)	// admin_pm [name] [message]
{
	if(!cmd_access(id, level, cid, 3) || toggleCache == -1)
		return PLUGIN_HANDLED
		
		
	new args[300]; read_args(args, charsmax(args) )
	new target[32], message[192]
		
	strbreak(args, target, charsmax(target), message, charsmax(message) )
	
			
	new player = cmd_target(id, target, CMDTARGET_NO_BOTS)
	
	if(!player) 
	{
		
		client_print(id, print_console, "%L", id, "INVALID_PLAYER", target) 
	}
	else
	{
		format(message, charsmax(message), "[FROM ADMIN] %s", message)
		printMessage(player, id, message)
	}
	
	return PLUGIN_HANDLED
}
public cmdAdminBan(id, level, cid)	// pm_ban [user]
{
	if(!cmd_access(id, level, cid, 2) || toggleCache == -1)
		return PLUGIN_HANDLED
	
		
	new target[32]; read_argv(1, target, charsmax(target) )
	
			
	new player = cmd_target(id, target, CMDTARGET_NO_BOTS)
	
	
	if(!player) 
	{
		
		client_print(id, print_console, "%L", id, "INVALID_PLAYER", target) 
	}
	else
		banUser(id, player)
	
	return PLUGIN_HANDLED
}

stock str_explode(const string[], delimiter, output[][], output_size, output_len)
{
	new i, pos, len = strlen(string)
	
	do
	{
		pos += (copyc(output[i++], output_len, string[pos], delimiter) + 1)
	}
	while(pos < len && i < (output_size-1))
	pos += (copy(output[i++], output_len, string[pos]) + 1)
	
	return i
}
	
public menuShortcuts(id, szMenuItem[])
{
	strtolower(szMenuItem)
	switch(szMenuItem[0])
	{
		case 'o':
		{
			if(szMenuItem[1] == 'n' && szMenuItem[2] == EOS)	//on
			{
				if(onBits[id] )
				{
					client_print(id, print_chat, "%L", id, "PM_ENABLED")
					
				}
				else
					toggle(id)
			}
			else if(szMenuItem[1] == 'f' && szMenuItem[2] == 'f' && szMenuItem[3] == EOS)	//off
			{
				if(onBits[id])
					toggle(id)
				else
				{
					client_print(id, print_chat, "%L", id, "PM_DISABLED")
				}
			}
			else
				return 0
		}
		case 'b':
		{
			if(equal(szMenuItem, "block") )
			{
				new playersMenu = menu_create("Block User", "mh_block")
				mhlp_getPlayerMenu(playersMenu)
				menu_display(id, playersMenu, 0)
			}
			else
				return 0
		}
		case 'h':
		{
			if(equal(szMenuItem, "help") )
				displayHelp(id)
			else
				return 0
		}
		default: return 0
	}
	
	return 1
}
displayHelp(id)
{
	new motd[1124], len
	
	if( bannedBits[id] )		
	{
		len = formatex(motd, charsmax(motd), "<br><br><br><font color=red><h2>You are currently BANNED from Private Messaging!</h2><br>")
		len+= formatex(motd[len], charsmax(motd) - len, "An admin has banned you from private messaging. Sorry</font>")
		show_motd(id, motd, "Private Message Help -Banned-")
		
		return 1
	}
	
	len = formatex(motd, charsmax(motd), "<font color=red><h3>You have Private Messaging")
	len+= formatex(motd[len], charsmax(motd) - len, " <i>%s</i></h3><br>", (onBits[id]) ? "ENABLED" : "DISABLED")
	len+= formatex(motd[len], charsmax(motd) - len, "You have the following players blocked: <ul>")
	
	new players[32], num 
	get_players(players, num, "ch")
	
	for(new name[32],sid[32],player, i = 0; i < num; i++)
	{
		player = players[i]
		if(blockList[id][player] )	
		{
			get_user_name(player, name, charsmax(name) )
			get_user_authid(player, sid, charsmax(sid) )
			len+= formatex(motd[len], charsmax(motd) - len, "<li> %s (%s)", name, sid)
		}
	}
	
	len+= formatex(motd[len], charsmax(motd) - len, "</ul><br><br><h3>The following commands can be used:</h3><ul>")
	len+= formatex(motd[len], charsmax(motd) - len, "<li> say /pm OR say_team /pm OR pm_menu (in console)  -Private Message Menu")
	len+= formatex(motd[len], charsmax(motd) - len, "<li> say /pm &#60;nick&#62; [&#60;message&#62;] OR pm &#60;nick&#62; [&#60;message&#62;] (in console) -Sends a private message to specified player")
	len+= formatex(motd[len], charsmax(motd) - len, "<li> say /block &#60;nick&#62; OR pm_block &#60;nick&#62;  -Blocks the specified player")
	len+= formatex(motd[len], charsmax(motd) - len, "<li> say /admin [&#60;message&#62;]   -Sends a message to admins only")
	len+= formatex(motd[len], charsmax(motd) - len, "<li> say /pageadmin  -Pages all connected admins")
	if(access(id, ADMIN_FLAG) )
	{
		len+= formatex(motd[len], charsmax(motd) - len, "<br><br><b><u>ADMIN COMMANDS (Either use PM Menu or these commands)</u></b>")
		len+= formatex(motd[len], charsmax(motd) - len, "<li> admin_pm &#60;nick&#62; -Admin message specified player")
		len+= formatex(motd[len], charsmax(motd) - len, "<li> pm_ban &#60;nick&#62; -Ban specified player from Private Messaging")
	}
	len+= formatex(motd[len], charsmax(motd) - len, "<br><br><h5>%s %s written by WeeKenD, updated by DusT.", PLUGIN, VERSION)
	
	show_motd(id, motd, "Private Message Help")
	
	return 1
}
public cmdPMmenu(id)	
{
	if(toggleCache == -1)
		return PLUGIN_CONTINUE

	menu_display(id, g_mainMenu, 0)
	
	return PLUGIN_HANDLED
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
		case 1:	toggle(id)
		case 2: 
		{
			new playersMenu = menu_create("Block User", "mh_block")
			mhlp_getPlayerMenu(playersMenu)
			menu_display(id, playersMenu, 0)
		}
		case 3:	pageAdmin(id)
		case 4:	displayHelp(id)
		case 5:
		{
			new playerMenu = menu_create("Player to Ban", "mh_ban", ADMIN_FLAG)
			mhlp_getBanPlayerMenu(playerMenu)
			menu_display(id, playerMenu, 0)
		}
	}
	
	
	return PLUGIN_HANDLED
}    
public mh_block(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new choice, acs, cb
	new data[3], name[32]
	menu_item_getinfo(menu, item, acs, data, charsmax(data), name, charsmax(name), cb)
	
	choice = str_to_num(data)
	if(!!choice)	
		blockUser(id, choice)
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public mh_ban(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new choice, acs, cb
	new data[3], name[32]
	menu_item_getinfo(menu, item, acs, data, charsmax(data), name, charsmax(name), cb)
	
	choice = str_to_num(data)
	if(!!choice)	
		banUser(id, choice)
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}


mhlp_getPlayerMenu(&p_menu, itemAccess=0, getPlayersFlags[]="ch") 
{ 
    new players[32], plyrCnt 
    new sz_name[32], sz_info[8] 
    get_players(players, plyrCnt, getPlayersFlags) 
     
    for(new player, i = 0; i < plyrCnt; i++) 
    { 
        player = players[i] 
        get_user_name(player, sz_name, charsmax(sz_name) ) 
        formatex(sz_info, charsmax(sz_info), "%d", player) 
        menu_additem(p_menu, sz_name, sz_info, itemAccess) 
    } 
     
    menu_setprop(p_menu, MPROP_EXIT, MEXIT_ALL) 
    return plyrCnt 
}
mhlp_getBanPlayerMenu(&p_menu)
{ 
    new players[32], plyrCnt, adminCnt
    new sz_name[32], sz_info[8] 
    get_players(players, plyrCnt, "ch") 
     
    for(new player, i = 0; i < plyrCnt; i++) 
    { 
        player = players[i] 
        if(!access(player, ADMIN_IMMUNITY))
        {
            get_user_name(player, sz_name, charsmax(sz_name) ) 
            formatex(sz_info, charsmax(sz_info), "%d", player) 
            menu_additem(p_menu, sz_name, sz_info, ADMIN_FLAG) 
        }
        else 
            adminCnt++		
    } 
     
    if(adminCnt == plyrCnt)
	menu_additem(p_menu, "All users have immunity.", "0", ADMIN_FLAG)
	
    menu_setprop(p_menu, MPROP_EXIT, MEXIT_ALL) 
    return plyrCnt - adminCnt
}


	
public bool:toggle(id)
{
	onBits[id] = 1 - onBits[id]

	client_print(id, print_chat, "%L", id, (onBits[id]) ? "PM_ENABLED" : "PM_DISABLED")
	
	return bool:onBits[id];
}
public bool:blockUser(id, victim)
{
	blockList[id][victim] = 1 - blockList[id][victim]

	new name[32]; get_user_name(victim, name, charsmax(name) )
	
	client_print(id, print_chat, "%L", id, (blockList[id][victim]) ? "USER_BLOCKED" : "USER_UNBLOCKED", name)
	return bool:blockList[id][victim];
}
public bool:banUser(admin, victim)
{
	
	bannedBits[victim] = 1 - bannedBits[victim]
	
	new adminName[32], victimName[32]
	get_user_name(admin, adminName, charsmax(adminName) )
	get_user_name(victim, victimName, charsmax(victimName) )
	log_value = get_pcvar_num(toggle_log);
	if(log_value)
	{
		if(bannedBits[victim])
			log_to_file( LogFile, "'%s' has banned '%s' from Private Messaging",adminName,victimName);
		else
			log_to_file( LogFile, "'%s' has unbanned '%s' from Private Messaging",adminName,victimName);
	}

	show_activity(admin, adminName, "%L", LANG_PLAYER, (bannedBits[victim]) ? "BAN_SET" : "BAN_UNSET",victimName)
		
	return bool:bannedBits[victim]
}

	
public printMessage(reciever, sender, const message[])
{
	if(contain(message, "ADMIN]") == -1)	
	{
			
		if(toggleCache == 0 && !is_user_alive(sender) && is_user_alive(reciever) )	
		{
			client_print(sender, print_chat, "%L", sender, "BAD_TARGET")
			client_print(sender, print_console, "%L", sender, "BAD_TARGET")
			return 0
		}
			
		else if(blockList[reciever][sender] || !(onBits[reciever]) )	
		{
			client_print(sender, print_chat, "%L", sender, "BLOCKED_MSG")
			client_print(sender, print_console, "%L", sender, "BLOCKED_MSG")
			return 0
		}
	}
	else if(access(reciever, ADMIN_FLAG) && (blockList[reciever][sender] || !(onBits[reciever])) )	
		return 0
	
		
	new output[192], name[32], rname[32]
	get_user_name(sender, name, charsmax(name) )
	get_user_name(reciever, rname, charsmax(rname) )
	
		
	if(message[0] == EOS)	
		formatex(output, charsmax(output), "^x04[PM] %s^x01: [PAGE]", name)
	else
		formatex(output, charsmax(output), "^x04[PM] %s -> %s^x01: %s", name, rname, message)
		
		
		
	static saytext = 0
	if(!saytext)	saytext = get_user_msgid("SayText")
	
		
	message_begin(MSG_ONE, saytext, {0,0,0}, reciever)
	write_byte(reciever)
	write_string(output)
	message_end()
	
	if(sender != reciever)	
	{
		message_begin(MSG_ONE, saytext, {0,0,0}, sender)
		write_byte(sender)
		write_string(output)
		message_end()
	}
	log_value = get_pcvar_num(toggle_log);
	if(log_value)
		log_to_file( LogFile, "'%s' -> '%s' = '%s'",name,rname,message);

	if(pm_sound[0])
		client_cmd(reciever, "speak ^"sound/%s^"", pm_sound)
	
	return 1
}
