#include <sourcemod>
#include <sdktools>

enum
{
    quit_retry,
    restart_retry,

    MAX_CONVARS
};

ConVar g_ConVars[MAX_CONVARS];

public Plugin myinfo = 
{
    name = "SM Utilities | Server Utilities",
    author = "Heapons",
    description = "Tools and utilities for managing servers",
    version = "26w32a",
    url = "https://github.com/Heapons/SM-Utilities"
};

public void OnPluginStart()
{
    /* ConVars */
    g_ConVars[quit_retry]                = CreateConVar("sm_quit_retry", "1", "Whether to send retry command to clients on quit.", _, true, 0.0, true, 1.0);
    g_ConVars[restart_retry]             = CreateConVar("sm_restart_retry", "1", "Whether to send retry command to clients on restart.", _, true, 0.0, true, 1.0);

    /* Commands */
    RegServerCmd("quit", Command_Quit);
    RegServerCmd("_restart", Command_Restart);

    RegAdminCmd("sm_retry", Command_Retry, ADMFLAG_RCON);
}

/* Commands */
public Action Command_Quit(int args)
{
    if (g_ConVars[quit_retry].BoolValue)
    {
        Command_Restart(args);
    }
    return Plugin_Continue;
}

public Action Command_Restart(int args)
{
    if (g_ConVars[restart_retry].BoolValue)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            Command_Retry(i, 0);
        }
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action Command_Retry(int client, int args)
{
    if (client <= 0 || client > MaxClients)
        return Plugin_Continue;
    
    if (IsFakeClient(client))
        return Plugin_Continue;
        
    ClientCommand(client, "retry");
    
    return Plugin_Handled;
}
