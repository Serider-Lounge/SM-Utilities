#include <sourcemod>
#include <multicolors>

#define PLUGIN_PREFIX "{#4C4C4C}[{#F69E1D}Source{#5596CF}Mod{#4C4C4C}]\x01"

ConVar mp_friendlyfire;

public Plugin myinfo = 
{
    name = "SM Utilities | Friendly-Fire",
    author = "Heapons",
    description = "Tools and utilities for Team Fortress 2 Classified",
    version = "26w07a",
    url = "https://github.com/Heapons/SM-Utilities"
};

public void OnPluginStart()
{
    LoadTranslations("common.phrases");

    mp_friendlyfire = FindConVar("mp_friendlyfire");
    mp_friendlyfire.AddChangeHook(OnConVarChanged);

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
    CPrintToChatAll(PLUGIN_PREFIX ... " \x04Friendly-Fire\x01: \x03%t", mp_friendlyfire.BoolValue ? "On" : "Off");
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    mp_friendlyfire.SetBool(false);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    mp_friendlyfire.SetBool(true);
}