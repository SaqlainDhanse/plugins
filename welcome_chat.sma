#include <amxmodx>

public plugin_init()
{
	register_plugin("Welcome Message", "1.0", "WeeKenD")
}

public client_connect(id)
{
	set_task(10.0,"show_message",id)
}

public show_message(id)
{
	client_print(id, print_chat, "Welcome to the server!!!")
}

