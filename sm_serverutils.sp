#include <sourcemod>
#include <sdktools>

enum
{
    quit_retry,
    restart_retry,
    waitingforplayers_disable,

    MAX_CONVARS
};

ConVar g_ConVars[MAX_CONVARS];

public Plugin myinfo = 
{
    name = "SM Utilities | Server Utilities",
    author = "Heapons",
    description = "Tools and utilities for managing servers",
    version = "26w15b",
    url = "https://github.com/Heapons/SM-Utilities"
};

public void OnPluginStart()
{
    /* Events */
    HookEvent("teamplay_round_active", Event_TeamplayRoundActive);

    /* ConVars */
    g_ConVars[quit_retry]                = CreateConVar("sm_quit_retry", "1", "Whether to send retry command to clients on quit.", _, true, 0.0, true, 1.0);
    g_ConVars[restart_retry]             = CreateConVar("sm_restart_retry", "1", "Whether to send retry command to clients on restart.", _, true, 0.0, true, 1.0);
    g_ConVars[waitingforplayers_disable] = CreateConVar("sm_waitingforplayers_disable", "1", "Whether to disable waiting for players on round start.", _, true, 0.0, true, 1.0);

    /* Commands */
    RegServerCmd("quit", Command_Quit);
    RegServerCmd("_restart", Command_Restart);

    RegAdminCmd("sm_retry", Command_Retry, ADMFLAG_RCON);
}

/* Events */
public void Event_TeamplayRoundActive(Event event, const char[] name, bool dontBroadcast)
{
    if (GameRules_GetProp("m_bInWaitingForPlayers"))
    {
        if (g_ConVars[waitingforplayers_disable].BoolValue)
        {
            ServerCommand("mp_waitingforplayers_cancel 1");
        }
    }
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
            if (!IsFakeClient(i))
            {
                ClientCommand(i, "retry");
            }
        }
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action Command_Retry(int client, int args)
{
    if (!IsFakeClient(client))
    {
        ClientCommand(client, "retry");
    }
    return Plugin_Handled;
}