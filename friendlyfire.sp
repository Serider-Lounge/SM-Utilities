#include <sourcemod>
#include <multicolors>

#define PLUGIN_PREFIX "[\x03SM Utilities\x01]"

public Plugin myinfo = 
{
    name = "SM Utilities | Friendly-Fire",
    author = "Heapons",
    description = "Tools and utilities for Team Fortress 2 Classified",
    version = "26w31a",
    url = "https://github.com/Heapons/SM-Utilities"
};

enum
{
    mp_friendlyfire,

    friendlyfire_endround,

    MAX_CONVARS
}

ConVar g_ConVars[MAX_CONVARS];

public void OnPluginStart()
{
    LoadTranslations("common.phrases");

    g_ConVars[mp_friendlyfire] = FindConVar("mp_friendlyfire");
    g_ConVars[mp_friendlyfire].AddChangeHook(OnConVarChanged);

    g_ConVars[friendlyfire_endround] = CreateConVar("sm_friendlyfire_endround", "1", "Enable friendly-fire at the end of rounds.", _, true, 0.0, true, 1.0);

    if (HookEventEx("teamplay_round_start", Event_RoundStart))
    {
        HookEvent("teamplay_round_win", Event_RoundEnd);
        HookEvent("arena_win_panel", Event_RoundEnd);
    }
    else
    {
        HookEvent("round_start", Event_RoundStart);
        HookEvent("round_end", Event_RoundEnd);
    }
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    CPrintToChatAll(PLUGIN_PREFIX ... " \x04Friendly-Fire\x01: \x03%t", g_ConVars[mp_friendlyfire].BoolValue ? "On" : "Off");
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_ConVars[mp_friendlyfire].RestoreDefault();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    g_ConVars[mp_friendlyfire].SetBool(true);
}