#include <amxmodx>

public plugin_init()
{
	register_plugin("Welcome Message", "1.0", "WeeKenD")
}

public client_putinserver(id)
{
	set_task(10.0, "show_message", id)
}

public show_message(id)
{
	client_print(id, print_center, "Welcome to the server!!!")
}

public client_disconnected(id)
{
	if(task_exists(id))
	{
		remove_task(id)
	}
}
