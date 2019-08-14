#include <amxmodx>
#include <amxmisc>
#include <jailbreak_core>
#include <cstrike>
#include <fun>

#define PLUGIN  "JB Roulette"
#define VERSION "1.0"
#define AUTHOR  "Saqlain"

new spinwheel_flag;
new spinwheel[51][33];
new player_bets[33];
new number_bets[33];
new reward[33];
new disconnected[33];
new spin_number;
new spin_remaining_time;
new maxAmount;
new unbiased_win;

new betting_time
new min_bet_amount
//new betting_cooldown
new betting_time_cvar
new min_bet_amount_cvar
new betting_cooldown_cvar

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	betting_time_cvar = register_cvar("roulette_bet_time", "15")
	betting_cooldown_cvar = register_cvar("roulette_cooldown", "120")
	min_bet_amount_cvar = register_cvar("roulette_min_bet", "50")
	register_clcmd("say", "client_say_cmd", 0, "-Roulette")
	register_clcmd("say_team", "client_say_cmd", 0, "-Roulette")
	arrayset(player_bets, 0, 33)
	arrayset(number_bets, 0, 33)
	arrayset(reward, 0 , 33)
	arrayset(disconnected, 0 , 33)
	for(new i=0; i<51; i++)
	{
		for(new j=0; j<33; j++)
			spinwheel[i][j] = 0
	}
	maxAmount = 0
	spin_number = 0
	unbiased_win = 0
	set_task(10.0, "start_spin_adv")
}

public client_disconnect(id)
{
	new szName[40]
	disconnected[id] = 1
	get_user_name(id, szName, charsmax(szName))
	if(spinwheel[0][id] > 0)
	{
		set_hudmessage(255, 0, 0, 0.01, 0.4, 0, 0.0, 5.0, 0.3, 0.3, 3)
		show_hudmessage(0, "[Roulette] %s has disconnected and has lost all the betted money", szName)
	}
}

public start_spin_adv()
{
	betting_time = get_pcvar_num(betting_time_cvar);
	spinwheel_flag = 1
	reset_stats()
	spin_remaining_time = betting_time + 1
	run_timer()
}

public reset_stats()
{
	arrayset(player_bets, 0, 33)
	arrayset(number_bets, 0, 33)
	arrayset(reward, 0 , 33)
	arrayset(disconnected, 0 , 33)
	for(new i=0; i<51; i++)
	{
		for(new j=0; j<33; j++)
			spinwheel[i][j] = 0
	}
	maxAmount = 0
	spin_number = 0
	unbiased_win = 0
}

public run_timer()
{
	if(spin_remaining_time <= 0)
	{	
		spinwheel_flag = 0
		start_spin()
	}
	else
	{
		spin_remaining_time--
		set_hudmessage(0, 255, 0, 0.01, 0.2, 0, 0.0, 5.0, 0.3, 0.3, 1)
		show_hudmessage(0, "Roulette Round has started, you have %d seconds for betting, say /bet <1 - 50> <Amount>", spin_remaining_time)
		set_task(1.0, "run_timer")
	}
}

public client_say_cmd(id, level, cid)
{
	new sString[96]
	new sOutput[3][32]
	new numb, amount
	read_args(sString, charsmax(sString))
	remove_quotes(sString)
	if(equali(sString, "/bet"))
	{
		displayBets(id)
		return 1
	}
	str_explode(sString, ' ', sOutput, 3, 31)
	if(equali(sOutput[0], "/bet"))
	{
		numb = str_to_num(sOutput[1])
		amount = str_to_num(sOutput[2])
		min_bet_amount = get_pcvar_num(min_bet_amount_cvar);
		if(!spinwheel_flag)
		{
			client_print(id, print_chat, "[Roulette] You are not allowed to play roulette at this time.")
			return 1
		}

		else if(numb<1 || numb>50)
		{
			client_print(id, print_chat, "[Roulette] You can select a number from 1 to 50 only.")
			return 1
		}

		else if(amount > get_money(id))
		{
			client_print(id, print_chat, "[Roulette] You do not have the specified amount to bet")
			return 1
		}

		else if(amount < min_bet_amount)
		{
			client_print(id, print_chat, "[Roulette] You can't bet for less than %d$", min_bet_amount)
			return 1
		}

		else if(spinwheel[numb][id] == 0 && player_bets[id] == 5)
		{
			client_print(id, print_chat, "[Roulette] You can't bet on more than 5 numbers")
			return 1
		}

		else if(spinwheel[numb][id] == 0 && number_bets[id] == 5)
		{
			client_print(id, print_chat, "[Roulette] Maximum of 5 players can bet on a number")
			return 1
		}
		else 
		{	
			set_bet(id, numb, amount)
			return 1
		}
		return 1
	}
	return 0
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

public set_bet(id, numb, amount)
{
	new szName[40]
	remove_money(id, amount)
	if(spinwheel[numb][id] == 0)
	{
		player_bets[id]++
		number_bets[id]++
	}
	spinwheel[numb][id] += amount
	spinwheel[numb][0] += amount
	spinwheel[0][id] += amount
	spinwheel[0][0] += amount
	get_user_name(id, szName, 39)
	set_hudmessage(0, 255, 0, 0.01, 0.4, 0, 0.0, 3.0, 0.3, 0.3, 3)
	show_hudmessage(0, "[Roulette] %s has betted %d$ on the number %d", szName, amount, numb)
	check_bet_amounts()
}

public check_bet_amounts()
{
	new i
	for(i=1; i<33; i++)
		maxAmount = (maxAmount > spinwheel[0][i])? maxAmount : spinwheel[0][i]
	for(i=1; i<33; i++)
	{
		if(maxAmount > spinwheel[0][i] && spinwheel[0][i] != 0 && is_user_connected(i))
			client_print(i, print_chat, "[Roulette] Base amount for betting has been shifted to %d$. To stay in the round, you must bet more %d$ within %d seconds", maxAmount, (maxAmount - spinwheel[0][i]), spin_remaining_time)
	}
}

public start_spin()
{
	new i, Players[32], iPlayer, num
	get_players(Players, num, "ch")
	set_hudmessage(0, 255, 0, 0.01, 0.2, 0, 0.0, 5.0, 0.3, 0.3, 1)
	show_hudmessage(0, "[Roulette] Betting period on Roulette has ended. Roulette is rotating.")

	for(i=0; i<num; i++)
	{
		iPlayer = Players[i]
		if(maxAmount > spinwheel[0][iPlayer])
			client_print(iPlayer, print_chat, "[Roulette] You were ruled out of this round because you betted %d$ less than the base amount.", (maxAmount - spinwheel[0][iPlayer]))
	}
	set_task(5.0, "result_spin")
}

public result_spin()
{
	new Players[32], iPlayer, num
	new i, names[5][60], szName[40], count = 0
	spin_number = random_num(1,50)
	for(i=1; i<33; i++)
	{
		if((spinwheel[spin_number][i] != 0) && (maxAmount <= spinwheel[0][i]) && is_user_connected(i) && disconnected[i] == 0) //max amount can't be less than players total amount, but still added to check for safer condition
		{
			reward[i] = (spinwheel[0][0]) * (spinwheel[spin_number][i] / spinwheel[spin_number][0])
			
			if(get_user_flags(i) & ADMIN_RESERVATION) // to check if user is VIP
			{	
				if(reward[i] % 1 != 0)
					reward[i] = reward[i] - (reward[i] % 1) + 1
			}
			else
				reward[i] = reward[i] - (reward[i] % 1)

			add_money(i, reward[i])	

			get_user_name(i, szName, 39)
			formatex(names[count++], 59, "%s - %d$,", szName, reward[i])		
		}
	}
	if(count == 0)
	{	
		get_players(Players, num, "ch")
		for(i=0; i<num; i++)
		{
			if(spinwheel[0][Players[i]] >= maxAmount && is_user_connected(Players[i]) && disconnected[Players[i]] == 0)
				unbiased_win++
		}
		for(i=0; i<num; i++)
		{
			if(spinwheel[0][Players[i]] >= maxAmount && is_user_connected(Players[i]) && disconnected[Players[i]] == 0)
			{
				iPlayer = Players[i]
				reward[iPlayer] = (spinwheel[0][0]) / unbiased_win
			
				if(get_user_flags(iPlayer) & ADMIN_RESERVATION) // to check if user is VIP
				{	
					if(reward[iPlayer] % 1 != 0)
						reward[iPlayer] = reward[iPlayer] - (reward[iPlayer] % 1) + 1
				}
				else
					reward[iPlayer] = reward[iPlayer] - (reward[iPlayer] % 1)

				add_money(iPlayer, reward[iPlayer])	

			}
		}

		set_hudmessage(0, 255, 0, 0.01, 0.2, 0, 0.0, 10.0, 0.3, 0.3, 1)
		show_hudmessage(0, "[Roulette] Roulette has stopped on the number %d", spin_number)
		if(maxAmount > 0)
		{
			set_hudmessage(0, 255, 0, 0.01, 0.4, 0, 0.0, 10.0, 0.3, 0.3, 3)
			show_hudmessage(0, "[Roulette] As there were no right guessers of number %d whose total bet amount was %d, there are only unbiased winners for this round who placed highest bets", spin_number, maxAmount)
		}
		else
		{
			set_hudmessage(0, 255, 0, 0.01, 0.4, 0, 0.0, 10.0, 0.3, 0.3, 3)
			show_hudmessage(0, "[Roulette] Nobody betted in this round")
		}
	}

	else
	{
		while(count < 5)
			formatex(names[count++], 59, "");
		set_hudmessage(0, 255, 0, 0.01, 0.2, 0, 0.0, 10.0, 0.3, 0.3, 1)
		show_hudmessage(0, "[Roulette] Roulette has stopped on the number %d", spin_number)
		set_hudmessage(0, 255, 0, 0.01, 0.4, 0, 0.0, 10.0, 0.3, 0.3, 3)
		show_hudmessage(0, "[Roulette] Winners:- %s %s %s %s %s", names[0], names[1], names[2], names[3], names[4])
		
	}

	//betting_cooldown = get_pcvar_float(betting_cooldown_cvar);
	set_task(get_pcvar_float(betting_cooldown_cvar), "start_spin_adv")
}

public add_money(id, money)
{
	jb_set_user_cash(id, (jb_get_user_cash(id) + money))
	return 1;
}

public remove_money(id, money)
{
	jb_set_user_cash(id, (jb_get_user_cash(id) - money))
	return 1;
}

public get_money(id)
{
	return jb_get_user_cash(id);
}

displayBets(id)
{
	static motd[10000]
	new len, i, j, szName[40]
	
	len = formatex(motd, charsmax(motd), "<font color=red><h2>Betting Details</h2></font><br>")

	for(i=1; i<=50; i++)
	{
		len+= formatex(motd[len], charsmax(motd) - len, "<br><b>Number %d :-</b>", i)
		for(j=1; j<=32; j++)
		{
			if(spinwheel[i][j] > 0)
			{
				get_user_name(j, szName, charsmax(szName))
				len+= formatex(motd[len], charsmax(motd) - len, " %s - %d,", szName, spinwheel[i][j])
			
			}	
		}	
	}

	len+= formatex(motd[len], charsmax(motd) - len, "<br><h5><font color=red>%s %s by %s</font></h5>", PLUGIN, VERSION, AUTHOR)		
	
	show_motd(id, motd, "Betting Details")
	
	return 1
}
