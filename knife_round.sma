#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < hamsandwich >
#include < colorchat >

#define PLUGIN "Knife Start"
#define VERSION "1.0"
#define AUTHOR "Saqlain"

new const KR_TAG[] = "[UGC Championship]";

new bool:g_bKnifeRound;
new bool:g_bVotingProcess;
new g_iMaxPlayers;
new g_Votes[ 2 ];
new g_pSwapVote;
//new g_pNoslash;

public plugin_init() {
	register_plugin( PLUGIN, VERSION, AUTHOR );

	g_pSwapVote = register_cvar( "kr_swapvote", "1" );   
	//g_pNoslash = register_cvar( "kr_noslash", "0" );	
	
	register_clcmd( "say /kf", "CmdKnifeRound", ADMIN_BAN, "Start Knife Round" );
	register_clcmd( "say /kr", "CmdKnifeRound", ADMIN_BAN, "Start Knife Round" );
	register_concmd( "say /kniferound", "CmdKnifeRound", ADMIN_BAN, "Start Knife Round" );
	register_clcmd( "say /rr", "CmdRestartRound", ADMIN_BAN, "Restart Round" );
	register_clcmd( "say /swap", "CmdSwapTeams", ADMIN_BAN, "Swap teams" );
	
	register_clcmd( "shield", "BlockCmds" );
	register_clcmd( "cl_rebuy", "BlockCmds" );
	
	register_event( "CurWeapon", "EventCurWeapon", "be", "2!29" );
	
	register_logevent( "EventRoundEnd", 2, "0=World triggered", "1=Round_Draw", "1=Round_End" );
	
	register_dictionary( "kniferound.txt" );
	
	register_menucmd( register_menuid( "\rSwap teams?" ), 1023, "MenuCommand" );
	
	//RegisterHam( Ham_Weapon_PrimaryAttack, "weapon_knife", "HamKnifePrimAttack" );
	
	g_iMaxPlayers = get_maxplayers( );

	
}

public EventCurWeapon( id ) {
	if( g_bKnifeRound ) engclient_cmd( id, "weapon_knife" );
	return PLUGIN_CONTINUE;
}

public CmdRestartRound( id, level, cid ) {
	if ( !cmd_access( id, level, cid, 1 ) ) return PLUGIN_HANDLED;
	
	g_bKnifeRound = false;
	server_cmd( "sv_restartround 1" );
	
	return PLUGIN_CONTINUE;
}

public CmdKnifeRound( id, level, cid ) {    
	if( !cmd_access( id, level, cid, 1 ) ) return PLUGIN_HANDLED;
	
	CmdRestartRound( id, level, cid );  
	
	set_task( 2.0, "KnifeRoundStart", id );
	
	ColorChat( 0, RED, "%L", 0, "KR_STARTED", KR_TAG );
	
	return PLUGIN_CONTINUE;
}

public CmdSwapTeams( id,level,cid ) {
	if( !cmd_access( id, level, cid, 1 ) ) return PLUGIN_HANDLED;
	
	SwapTeams( );
	CmdRestartRound( id, level, cid );
	
	return PLUGIN_CONTINUE;
}

public KnifeRoundStart( ) {
	g_bKnifeRound = true;
	g_bVotingProcess = false;
	
	new players[ 32 ], num;
	get_players( players, num );
	
	for( new i = 0; i < num ; i++ )
	{
		new item = players[ i ];
		EventCurWeapon( item );
	}
	
	return PLUGIN_CONTINUE;
}

public SwapTeams( ) {
	for( new i = 1; i <= g_iMaxPlayers; i++ ) {
		if( is_user_connected( i ) )
		{
			switch( cs_get_user_team( i ) )
			{
				case CS_TEAM_T: cs_set_user_team( i, CS_TEAM_CT );			
				case CS_TEAM_CT: cs_set_user_team( i, CS_TEAM_T );
			}
		}
	}
}

public EventRoundEnd( ) {
	if( g_bKnifeRound && get_pcvar_num( g_pSwapVote ) ) {
		new players[ 32 ], num;
		get_players( players, num, "ae", "TERRORIST" );
		
		if(!num) 
		{
			ColorChat( 0, BLUE, "%L", 0, "KR_WIN_CT", KR_TAG ); 
			set_task( 6.0, "vote_ct" );
		}
		else
		{	        
			ColorChat( 0, RED, "%L", 0, "KR_WIN_T", KR_TAG );
			set_task( 6.0, "vote_t" );  
		}    
	}
	g_bKnifeRound = false;
	
	return PLUGIN_CONTINUE;
}

public vote_t( ) {
	for( new i = 1; i <= g_iMaxPlayers; i++ ) {
		if( is_user_alive( i ) && cs_get_user_team( i ) == CS_TEAM_T )
		{
			ShowMenu( i );
		}
	}
	set_task( 8.0, "finishvote" );
}

public vote_ct( ) {
	for( new i = 1; i <= g_iMaxPlayers; i++ ) {
		if( is_user_alive( i ) && cs_get_user_team( i ) == CS_TEAM_CT )
		{
			ShowMenu( i );
		}
	}
	set_task( 8.0, "finishvote" );
}

public ShowMenu( id ) {
	g_bVotingProcess = true;
	
	if( g_bVotingProcess ) {
		new szMenuBody[ 256 ], keys;

		new nLen = format( szMenuBody, 255, "\rSwap teams?^n" );
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\y1. \wYes" );
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\y2. \wNo" );
		nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\y0. \wExit" );

		keys = ( 1<<0 | 1<<1 | 1<<9 );

		show_menu( id, keys, szMenuBody, -1 );
	}
	
	return PLUGIN_CONTINUE;
}

public MenuCommand( id, key ) {
	if( !g_bVotingProcess ) return PLUGIN_HANDLED;
	
	new szName[ 32 ];
	get_user_name( id, szName, charsmax( szName ) );
	
	switch( key )
	{
		case 0: 
		{
			g_Votes[ 0 ]++;
			ColorChat( 0, GREEN, "%L", 0, "KR_VOTE_YES", KR_TAG, szName );
		}
		case 1: 
		{
			g_Votes[ 1 ]++;
			ColorChat( 0, RED, "%L", 0, "KR_VOTE_NO", KR_TAG, szName );
		}  
		case 9: show_menu( id, 0, "" );
	} 
	
	return PLUGIN_HANDLED;
}

public finishvote( ) {
	if( !g_bVotingProcess ) return PLUGIN_HANDLED;
	
	server_cmd( "sv_restartround 1" );
	
	if ( g_Votes[ 0 ] > g_Votes[ 1 ] ) 
	{
		ColorChat( 0, GREEN, "%L", 0, "KR_SWITCH_TEAMS", KR_TAG );
		SwapTeams( );
	}
	else
	{
		ColorChat( 0, BLUE, "%L", 0, "KR_STAY_IN", KR_TAG );
		server_cmd( "sv_restartround 1" );
	}
	
	g_Votes[ 0 ] = 0;
	g_Votes[ 1 ] = 0;
	g_bVotingProcess = false;
	
	return PLUGIN_HANDLED;
}
/*
public HamKnifePrimAttack( iEnt ) {
	if( g_bKnifeRound && get_pcvar_num( g_pNoslash ) ) 
	{
		ExecuteHamB( Ham_Weapon_SecondaryAttack, iEnt );          
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}
*/
public BlockCmds( ) {
	if( g_bKnifeRound ) {
		return PLUGIN_HANDLED_MAIN;
	}
	return PLUGIN_CONTINUE;
}
