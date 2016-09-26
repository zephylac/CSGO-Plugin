public void OnPluginStart()
{
  RegAdminCmd("sm_kick", Command_Kick, ADMFLAG_KICK, "sm_kick <#userid|name> [reason]");
	RegAdminCmd("sm_afk_spec", command_Afk_Spec, ADMFLAG_AFK, "sm_afk_spec <#userid|name> | !spectate <#userid|name>");
}
 
public Action Command_Afk_Spec(int client, int args)
{
	if (args < 1)
	{
		PrintToConsole(client, "Usage: !spectate <#userid|name>");
		return Plugin_Handled;
	}
 
	char name[32];
        int target = -1;
	GetCmdArg(1, name, sizeof(name));
 
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientConnected(i))
		{
			continue;
		}
		char other[32];
		GetClientName(i, other, sizeof(other));
		if (StrEqual(name, other))
		{
			target = i;
		}
	}
 
	if (target == -1)
	{
		PrintToConsole(client, "Could not find any player with the name: \"%s\"", name);
		return Plugin_Handled;
	}
  RegAdminCmd("sm_afk_spec %d" , GetClientUserId(target)); 
 
	return Plugin_Handled;
}
