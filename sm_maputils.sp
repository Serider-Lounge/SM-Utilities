#include <sourcemod>
#include <sdktools>
#include <multicolors>
#undef REQUIRE_PLUGIN
#include <trainingmsg>
#define REQUIRE_PLUGIN

#include <serider/steam>

#define PLUGIN_PREFIX "{#4C4C4C}[{#F69E1D}Source{#5596CF}Mod{#4C4C4C}]\x01"

enum
{
	trainingmsg,

	MAX_LIBRARIES
}

bool g_Libraries[MAX_LIBRARIES];

public Plugin myinfo = 
{
    name = "SM Utilities | Maps Utilities",
    author = "Heapons",
    description = "Tools and utilities for managing maps",
    version = "26w07a",
    url = "https://github.com/Heapons/SM-Utilities"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("SendTrainingMessageToAll");
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("common.phrases");

    RegAdminCmd("sm_reloadmap", Command_ReloadMap, ADMFLAG_CHANGEMAP, "Reloads the current map.");

	RegServerCmd("nav_generate", Command_NavGenerate);
    RegServerCmd("nav_generate_incremental", Command_NavGenerate);
    RegServerCmd("sm_nav_generate", Command_NavGenerate);
    RegServerCmd("sm_nav_generate_incremental", Command_NavGenerate);

    int flags;
    static const char cheatCommands[][] = {
        "nav_generate",
        "nav_generate_incremental",
        "sm_nav_generate",
        "sm_nav_generate_incremental",
        "bot_kick"
    };
    for (int i = 0; i < sizeof(cheatCommands); i++)
    {
        flags = GetCommandFlags(cheatCommands[i]);
        if (flags & FCVAR_CHEAT)
        {
            SetCommandFlags(cheatCommands[i], flags & ~FCVAR_CHEAT);
        }
    }
}

public void OnAllPluginsLoaded()
{
    g_Libraries[trainingmsg] = LibraryExists("trainingmsg");
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "trainingmsg"))
    {
        g_Libraries[trainingmsg] = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "trainingmsg"))
    {
        g_Libraries[trainingmsg] = false;
    }
}

// https://github.com/alliedmodders/sourcemod/blob/0d299402b90e36374f73957c4fcc0e0b33a7754d/plugins/basecommands/map.sp
public Action Command_ReloadMap(int client, int args)
{
	char map[PLATFORM_MAX_PATH], displayName[PLATFORM_MAX_PATH];
	GetCurrentMap(map, sizeof(map));
	GetMapDisplayName(map, displayName, sizeof(displayName));
    Format(displayName, sizeof(displayName), "\x05%s\x01", displayName);

	CShowActivity2(client, PLUGIN_PREFIX ... " ", "%t", "Changing map", displayName);
	LogAction(client, -1, "\"%L\" reloaded map \"%s\"", client, displayName);

	char gameDir[64];
    GetGameFolderName(gameDir, sizeof(gameDir));
	if (StrEqual(gameDir, "tf2classified"))
	{
        int target = CreateEntityByName("info_target");
        if (target != -1)
        {
            float origin[3] = {0.0, 0.0, 0.0};
            TeleportEntity(target, origin, NULL_VECTOR, NULL_VECTOR);
            DispatchSpawn(target);
            
            Event event = CreateEvent("instructor_server_hint_create", true);
            if (event != INVALID_HANDLE)
            {
                event.SetString("hint_replace_key", "sm_reloadmap");
                char caption[64];
                Format(caption, sizeof(caption), "%t", "Changing map", displayName);
                event.SetString("hint_caption", caption);
                event.SetString("hint_icon_onscreen", "icon_tip");
                event.SetString("hint_icon_offscreen", "icon_tip");
                event.SetString("hint_static", "1");
                event.SetInt("hint_timeout", 0);
                event.SetInt("hint_target", target);
                event.Fire();
            }
        }
	}
	else if (g_Libraries[trainingmsg])
	{
		char hostname[256];
		GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));

		char trainingMessage[128];
		Format(trainingMessage, sizeof(trainingMessage), "%t", "Changing map", displayName);
		Format(displayName, sizeof(displayName), "{gold}%s{default}", displayName);

		SendTrainingMessageToAll(hostname, trainingMessage, TMSG_NOFLAGS);
	}

	DataPack dp;
	CreateDataTimer(3.0, Timer_ReloadMap, dp);
	dp.WriteString(map);

	return Plugin_Handled;
}

public Action Timer_ReloadMap(Handle timer, DataPack dp)
{
	char map[PLATFORM_MAX_PATH];

	dp.Reset();
	dp.ReadString(map, sizeof(map));

	ForceChangeLevel(map, "sm_reloadmap Command");

	return Plugin_Stop;
}

public Action Command_NavGenerate(int args)
{
    char map[PLATFORM_MAX_PATH], displayName[PLATFORM_MAX_PATH];
    GetCurrentMap(map, sizeof(map));
    GetMapDisplayName(map, displayName, sizeof(displayName));
    
    SetNextMap(displayName);
    
    CPrintToChatAll(PLUGIN_PREFIX ... " \x05%s\x01: Generating Navigation Mesh...", displayName);
	
	char gameDir[64];
    GetGameFolderName(gameDir, sizeof(gameDir));
	if (StrEqual(gameDir, "tf2classified"))
	{
        int target = CreateEntityByName("info_target");
        if (target != -1)
        {
            float origin[3] = {0.0, 0.0, 0.0};
            TeleportEntity(target, origin, NULL_VECTOR, NULL_VECTOR);
            DispatchSpawn(target);
            
            Event event = CreateEvent("instructor_server_hint_create", true);
            if (event != INVALID_HANDLE)
            {
                event.SetString("hint_replace_key", "nav_generate");
                event.SetString("hint_caption", "Generating Navigation Mesh...");
                event.SetString("hint_icon_onscreen", "icon_tip");
                event.SetString("hint_icon_offscreen", "icon_tip");
                event.SetString("hint_static", "1");
                event.SetInt("hint_timeout", 0);
                event.SetInt("hint_target", target);
                event.Fire();
            }
        }
	}
	else if (g_Libraries[trainingmsg])
	{
		char hostname[256];
		GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
		SendTrainingMessageToAll(hostname, "Generating Navigation Mesh...", TMSG_NOFLAGS);
	}

    return Plugin_Continue;
}