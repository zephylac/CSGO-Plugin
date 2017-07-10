#pragma semicolon 1

#define _DEBUG 0

#include <sourcemod>
#include <system2> 

// DB Handles
new Handle:hDatabase = INVALID_HANDLE;
new Handle:hDatabase2 = INVALID_HANDLE;
//new Handle:hQuery = INVALID_HANDLE;

// Cvar Handles
new Handle:cvarEnabled = INVALID_HANDLE;
new Handle:cvarLoggingEnabled = INVALID_HANDLE;

// Globals
new bool:gEnabled;
new bool:gLoggingEnabled;

// Database Queries
new const String:DBQueries[6][] =
{
	"CREATE TABLE IF NOT EXISTS `pat` (`id` INT(10) NOT NULL AUTO_INCREMENT,`steam` VARCHAR(50) NOT NULL,`time` INT(11) NOT NULL DEFAULT '0',`last_played` INT(11) NOT NULL,`oldtime` INT(11) NOT NULL DEFAULT '0',PRIMARY KEY (`id`)) COLLATE='latin1_swedish_ci' ENGINE=MyISAM;",
	"SELECT * FROM `pat` WHERE `steam` = '%s'",
	"UPDATE `pat` SET `oldtime` = '%i' WHERE `steam` = '%s'",
	"UPDATE `pat` SET `time` = '%i' WHERE `steam` = '%s'",
	"UPDATE `pat` SET `last_played` = '%i' WHERE `steam` = '%s'",
	"INSERT INTO `pat` (`steam`, `time`, `last_played`) VALUES ('%s', '%i', '%s')"
};

new const String:DBQueries2[1][] =
{
	"SELECT connection_time FROM `hlstat_Players` INNER JOIN hlstats_PlayerUniqueIds WHERE `uniqueId` = '%s'"
};


new const String:DBQueriesLogs[2][] =
{
	"CREATE TABLE IF NOT EXISTS `pat_logs` (`id` INT(10) NOT NULL AUTO_INCREMENT, `hostname` VARCHAR(50) NOT NULL, `name` VARCHAR(50) NOT NULL, `steam` VARCHAR(50) NOT NULL, `command` VARCHAR(100) NOT NULL, `time` VARCHAR(50) NOT NULL, PRIMARY KEY (`id`)) COLLATE='latin1_swedish_ci' ENGINE=MyISAM;",
	"INSERT INTO `pat_logs` (`hostname`, `steam`, `name`, `command`, `time`) VALUES ('%s', '%s', '%s', '%s', '%i')"
};

// Plugin Info
public Plugin:myinfo = 
{
	name = "Player Activity Timer",
	author = "zephylac",
	description = "Records player play time",
	version = "1.0",
	url = ""
};

public OnPluginStart ()
{
	// Create ConVars
	cvarEnabled = CreateConVar("sm_pat_enabled", "1", "Enables or disables the plugin: 0 - Disabled, 1 - Enabled (default)");
	gEnabled = true;
	
	cvarLoggingEnabled = CreateConVar("sm_pat_logging", "1", "Enables or disables logging commands: 0 - Disabled, 1 - Enabled (default)");
	gLoggingEnabled = true;
	
	// Hook Cvar Changes
	HookConVarChange(cvarEnabled, HandleCvars);
		
	// Connect to PAT Database
	new String:error[255];
	hDatabase = SQL_Connect("pat", true, error, sizeof(error));
	if (hDatabase == INVALID_HANDLE)
	{
		LogError("Unable to connect to pat database. Error: %s", error);
		LogMessage("[PAT] - Unable to connect to the database.");
	}
	
	// Connect to HLStats Database
	hDatabase2 = SQL_Connect("hlstat", true, error, sizeof(error));
	if (hDatabase2 == INVALID_HANDLE)
	{
		LogError("Unable to connect to hlstat database. Error: %s", error);
		LogMessage("[PAT] - Unable to connect to the database.");
	}
	
#if _DEBUG
	LogMessage("[patWatch DEBUG] - Connected to the database in OnPluginStart().");
#endif
	
	// Autoload Config
	AutoExecConfig(true, "pat");
	
	// If needed, create tables
	if (gEnabled)
	{
		SQL_TQuery(hDatabase, DBNoAction, DBQueries[0], DBPrio_High);
	}
	if (gLoggingEnabled)
	{
		SQL_TQuery(hDatabase, DBNoAction, DBQueriesLogs[0], DBPrio_High);
	}
}

public OnPluginEnd ()
{
	CloseHandle(hDatabase);
	hDatabase = INVALID_HANDLE;
	CloseHandle(hDatabase2);
	hDatabase2 = INVALID_HANDLE;
}

public OnConfigsExecuted ()
{
	gEnabled = GetConVarBool(cvarEnabled);
	gLoggingEnabled = GetConVarBool(cvarLoggingEnabled);
	
#if _DEBUG
	LogMessage("[patWatch DEBUG] - Fetched ConVars.");
#endif
}

public OnClientPostAdminCheck (client)
{
	// Check if plugin is enabled
	if (gEnabled)
	{
		// Add to database if needed
		decl String:query[255], String:authid[32];
		GetClientAuthString(client, authid, sizeof(authid));
		Format(query, sizeof(query), DBQueries[1], authid);
		SQL_TQuery(hDatabase, DBInsert, query, client, DBPrio_High);
	}
}

public DBInsert (Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogMessage("[patWatch] - DB Query Failed. Error: %s", error);
	}
	else
	{
		if (SQL_GetRowCount(hndl) <= 0)
		{
			// Not found, insert
			decl String:query[255], String:authid[32];
			GetClientAuthString(data, authid, sizeof(authid));
			
			Format(query, sizeof(query), DBQueries2[0], authid[8]);
			SQL_TQuery(hDatabase2, DBInsert2, query, DBPrio_High);
		}
		else{
			if (SQL_FetchRow(hndl))
			{
				decl String:query[255], String:authid[32];
				GetClientAuthString(data, authid, sizeof(authid));
				new todayDate = GetTime();
				new 	date = SQL_FetchInt(hndl, 3);
				
				if(date - todayDate > 604800){
					//Check for time in 1 week
					new time = SQL_FetchInt(hndl, 2);
					//Updating Date
					Format(query, sizeof(query), DBQueries[2], time, authid);
					SQL_TQuery(hDatabase2, DBNoAction, query, DBPrio_High);
					
					//Checking if player played enough
					Format(query, sizeof(query), DBQueries2[0], authid[8]);
					SQL_TQuery(hDatabase2, DBUpdate, query, DBPrio_High);
				}
				
			}
		}
			
	}
}

public DBInsert2 (Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogMessage("[patWatch] - DB Query Failed. Error: %s", error);
	}
	else
	{
		if (SQL_FetchRow(hndl))
		{
			decl String:query[255], String:authid[32];
			GetClientAuthString(data, authid, sizeof(authid));
			new time = 0;
			
			new date = GetTime();
			
			//Setting time found in Hlstat
			time = SQL_FetchInt(hndl, 1);
				
			Format(query, sizeof(query), DBQueries[3], authid, time , date);
			SQL_TQuery(hDatabase, DBNoAction, query, DBPrio_High);
		}
	}
}

public DBUpdate (Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogMessage("[patWatch] - DB Query Failed. Error: %s", error);
	}
	else
	{
		if (SQL_FetchRow(hndl))
		{
			decl String:query[255], String:authid[32];
			GetClientAuthString(data, authid, sizeof(authid));
			
			//Fetching time found in Hlstat
			new time = SQL_FetchInt(hndl, 2);
				
			Format(query, sizeof(query), DBQueries[3], time, authid);
			SQL_TQuery(hDatabase, DBUpdate2, query, DBPrio_High);
		}
	}
}

public DBUpdate2 (Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogMessage("[patWatch] - DB Query Failed. Error: %s", error);
	}
	else
	{
		if (SQL_FetchRow(hndl))
		{
			decl String:authid[32];
			GetClientAuthString(data, authid, sizeof(authid));
			
			//Fetching time found in Hlstat
			new time = SQL_FetchInt(hndl, 2);
			new oldtime = SQL_FetchInt(hndl, 4);
			
			if(time - oldtime > 25200){
				//lui donne le rang
				System2_RunThreadCommand(CommandCallback,"python /root/add.py serverfiles/csgo/addons/config/admins.cfg %s",authid);
			}
			else{
				//lui enleve le rang
				System2_RunThreadCommand(CommandCallback,"python /root/rm.py serverfiles/csgo/addons/config/admins.cfg %s",authid);	
			}
		}
	}
}

public DBNoAction (Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState(error);
	}
}

void CommandCallback(const char[] output, const int size, CMDReturn status, any data, const char[] command) {}

// Helper Functions
public HandleCvars (Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (cvar == cvarEnabled && StrEqual(newValue, "1"))
	{
		gEnabled = true;
	}
	else if (cvar == cvarEnabled && StrEqual(newValue, "0"))
	{
		gEnabled = false;
	}
	if (cvar == cvarLoggingEnabled && StrEqual(newValue, "1"))
	{
		gLoggingEnabled = true;
	}
	else if (cvar == cvarLoggingEnabled && StrEqual(newValue, "0"))
	{
		gLoggingEnabled = false;
	}
		
#if _DEBUG
	new String:cvarName[32];
	GetConVarName(cvar, cvarName, sizeof(cvarName)); 
	LogMessage("[patWatch DEBUG] - Cvar (%s) changed from \"%s\" to \"%s\" in HandleCvars().", cvarName, oldValue, newValue);
#endif
}

