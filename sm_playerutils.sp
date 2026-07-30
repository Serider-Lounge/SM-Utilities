#include <sourcemod>
#include <multicolors>

#include <serider/shared>

#undef REQUIRE_EXTENSIONS
#include <serider/tf2>
#define REQUIRE_EXTENSIONS

#define PLUGIN_PREFIX "[\x03SM Utilities\x01]"

enum
{
	fastrespawn_maxplayers,
    mp_disable_respawn_times,
    ignore_bots,
    ignore_spectators,

	MAX_CONVARS
}

ConVar g_ConVars[MAX_CONVARS];

public Plugin myinfo = 
{
    name = "SM Utilities | Player Utilities",
    author = "Heapons",
    description = "Tools and utilities for managing players",
    version = "26w31a",
    url = "https://github.com/Heapons/SM-Utilities"
};

public void OnPluginStart()
{
    /* ConVars */
    g_ConVars[fastrespawn_maxplayers] = CreateConVar("sm_fastrespawn_maxplayers", "8", "Maximum number of players required for fast respawn to be enabled.", _, true, 0.0, true, float(MAXPLAYERS));
    g_ConVars[ignore_bots] = CreateConVar("sm_fastrespawn_ignore_bots", "1", "Whether to ignore bots when counting players for fast respawn.", _, true, 0.0, true, 1.0);
    g_ConVars[ignore_spectators] = CreateConVar("sm_fastrespawn_ignore_spectators", "1", "Whether to ignore spectators when counting players for fast respawn.", _, true, 0.0, true, 1.0);

    g_ConVars[mp_disable_respawn_times] = FindConVar("mp_disable_respawn_times");

    for (int i = 0; i < MAX_CONVARS; i++)
    {
        switch (i)
        {
            case mp_disable_respawn_times:
                continue;
        }
        g_ConVars[i].AddChangeHook(OnConVarChanged);
    }

    UpdateFastRespawn();
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    UpdateFastRespawn();
}

void UpdateFastRespawn()
{
    if (g_ConVars[fastrespawn_maxplayers].IntValue <= 0)
        return;

    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        if (g_ConVars[ignore_bots].BoolValue && IsFakeClient(i))
            continue;

        if (g_ConVars[ignore_spectators].BoolValue && GetClientTeam(i) <= 1)
            continue;

        count++;
    }

    if (count <= g_ConVars[fastrespawn_maxplayers].IntValue)
    {
        g_ConVars[mp_disable_respawn_times].SetInt(2);
    }
    else
    {
        g_ConVars[mp_disable_respawn_times].SetInt(0);
    }
}

public void OnClientPutInServer(int client)
{
    UpdateFastRespawn();
}

public void OnClientDisconnect(int client)
{
    UpdateFastRespawn();
}